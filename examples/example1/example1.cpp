
#include <arrow/api.h>
#include <arrow/dataset/dataset.h>
#include <arrow/dataset/discovery.h>
#include <arrow/dataset/file_base.h>
#include <arrow/dataset/file_parquet.h>
//#include <arrow/dataset/expression.h>
#include <arrow/dataset/scanner.h>
#include <arrow/filesystem/filesystem.h>
#include <arrow/filesystem/path_util.h>
#include <parquet/exception.h>
#include <parquet/arrow/reader.h>
#include <parquet/schema.h>
#include <cstdlib>
#include <iostream>
#include <glog/logging.h>
#include <parquet/arrow/writer.h>
#include <arrow/filesystem/s3fs.h>
#include <filesystem>

using arrow::field;
using arrow::int16;
using arrow::Schema;
using arrow::Table;

namespace fs = arrow::fs;

namespace ds = arrow::dataset;

//using ds::string_literals::operator"" _;

constexpr int64_t ROW_GROUP_SIZE = 16 * 1024 * 1024;  // 16 MB


#define ABORT_ON_FAILURE(expr)                     \
  do {                                             \
    arrow::Status status_ = (expr);                \
    if (!status_.ok()) {                           \
      std::cerr << status_.message() << std::endl; \
      abort();                                     \
    }                                              \
  } while (0);

struct Configuration {
  // Increase the ds::DataSet by repeating `repeat` times the ds::Dataset.
  size_t repeat = 1;

  // Indicates if the Scanner::ToTable should consume in parallel.
  bool use_threads = true;

  // Indicates to the Scan operator which columns are requested. This
  // optimization avoid deserializing unneeded columns.
  //std::vector<std::string> projected_columns = {"pickup_at", "dropoff_at", "total_amount"};
    std::vector<std::string> projected_columns = {"RP_STORY_ID", "ENTITY_NAME" };
  //std::vector<std::string> projected_columns = {};

  // Indicates the filter by which rows will be filtered. This optimization can
  // make use of partition information and/or file metadata if possible.
  //ds::Expression filter =
  //    ds::greater(ds::field_ref("total_amount"), ds::literal(1000.0f));

  //ds::Expression filter;
  arrow::compute::Expression filter;

  ds::InspectOptions inspect_options{};
  ds::FinishOptions finish_options{};
} conf;

#define S3_ACCESS_KET "accesskey"
#define S3_SECRET_KEY "secretkey"
#define S3_BUCKET "sandbox-research"
#define S3_REGION "us-east-1"
#define S3_CONNECT_SCHEME "http"
#define S3_ENDPOINT_OVERRIDE "10.1.46.2:9000"

// todo read those from env

std::shared_ptr<fs::FileSystem> GetFileSystemFromUri(const std::string& uri,
                                                     std::string* path) {
  if (uri.substr(0, 5)=="minio"){
    arrow::fs::EnsureS3Initialized();
    std::shared_ptr<arrow::fs::S3FileSystem> s3fs;
    arrow::fs::S3Options options;
    options = arrow::fs::S3Options::FromAccessKey(S3_ACCESS_KET, S3_SECRET_KEY);
    options.endpoint_override = S3_ENDPOINT_OVERRIDE;
    options.scheme = S3_CONNECT_SCHEME;
    options.region = S3_REGION;
    s3fs = arrow::fs::S3FileSystem::Make(options).ValueOrDie();
    if (path)
      *path = uri.substr(std::strlen("minio://"));
    return std::make_shared<arrow::fs::SubTreeFileSystem>(S3_BUCKET, s3fs);
  }
  auto fs = fs::FileSystemFromUriOrPath(uri, path).ValueOrDie();
  return fs;
}

std::shared_ptr<ds::Dataset> GetDatasetFromDirectory(
  std::shared_ptr<fs::FileSystem> fs, std::shared_ptr<ds::ParquetFileFormat> format,
  std::string dir) {
  // Find all files under `path`
  fs::FileSelector s;
  s.base_dir = dir;
  s.recursive = true;

  ds::FileSystemFactoryOptions options;
  // The factory will try to build a child dataset.
  auto factory = ds::FileSystemDatasetFactory::Make(fs, s, format, options).ValueOrDie();

  // Try to infer a common schema for all files.
  auto schema = factory->Inspect(conf.inspect_options).ValueOrDie();
  // Caller can optionally decide another schema as long as it is compatible
  // with the previous one, e.g. `factory->Finish(compatible_schema)`.
  auto child = factory->Finish(conf.finish_options).ValueOrDie();

  ds::DatasetVector children{conf.repeat, child};
  auto dataset = ds::UnionDataset::Make(std::move(schema), std::move(children));

  return dataset.ValueOrDie();
}

std::shared_ptr<ds::Dataset> GetParquetDatasetFromMetadata(
  std::shared_ptr<fs::FileSystem> fs, std::shared_ptr<ds::ParquetFileFormat> format,
  std::string metadata_path) {
  ds::ParquetFactoryOptions options;
  auto factory =
    ds::ParquetDatasetFactory::Make(metadata_path, fs, format, options).ValueOrDie();
  return factory->Finish().ValueOrDie();
}

std::shared_ptr<ds::Dataset> GetDatasetFromFile(
  std::shared_ptr<fs::FileSystem> fs, std::shared_ptr<ds::ParquetFileFormat> format,
  std::string file) {
  ds::FileSystemFactoryOptions options;
  // The factory will try to build a child dataset.
  auto factory =
    ds::FileSystemDatasetFactory::Make(fs, {file}, format, options).ValueOrDie();

  // Try to infer a common schema for all files.
  auto schema = factory->Inspect(conf.inspect_options).ValueOrDie();
  // Caller can optionally decide another schema as long as it is compatible
  // with the previous one, e.g. `factory->Finish(compatible_schema)`.
  auto child = factory->Finish(conf.finish_options).ValueOrDie();

  ds::DatasetVector children;
  children.resize(conf.repeat, child);
  auto dataset = ds::UnionDataset::Make(std::move(schema), std::move(children));

  return dataset.ValueOrDie();
}

std::shared_ptr<ds::Dataset> GetDatasetFromPath(
  std::shared_ptr<fs::FileSystem> fs, std::shared_ptr<ds::ParquetFileFormat> format,
  std::string path) {
  auto info = fs->GetFileInfo(path).ValueOrDie();
  if (info.IsDirectory()) {
    return GetDatasetFromDirectory(fs, format, path);
  }

  auto dirname_basename = arrow::fs::internal::GetAbstractPathParent(path);
  auto basename = dirname_basename.second;

  if (basename == "_metadata") {
    return GetParquetDatasetFromMetadata(fs, format, path);
  }

  return GetDatasetFromFile(fs, format, path);
}

std::shared_ptr<ds::Scanner> GetScannerFromDataset(std::shared_ptr<ds::Dataset> dataset,
                                                   std::vector<std::string> columns,
                                                   const arrow::compute::Expression& filter,
                                                   bool use_threads) {
  auto scanner_builder = dataset->NewScan().ValueOrDie();

  if (!columns.empty()) {
    ABORT_ON_FAILURE(scanner_builder->Project(columns));
  }

  ABORT_ON_FAILURE(scanner_builder->Filter(filter));

  ABORT_ON_FAILURE(scanner_builder->UseThreads(use_threads));

  return scanner_builder->Finish().ValueOrDie();
}

std::shared_ptr<Table> GetTableFromScanner(std::shared_ptr<ds::Scanner> scanner) {
  return scanner->ToTable().ValueOrDie();
}

int main(int argc, char** argv) {
  auto format = std::make_shared<ds::ParquetFileFormat>();

  if (argc != 3) {
    std::cerr << "usage " << argv[0] << " src dst" << std::endl;
    // Fake success for CI purposes.
    return EXIT_SUCCESS;
  }

  std::string src = argv[1];
  if (!std::filesystem::exists(src)){
    LOG(ERROR) << "cannot find src: " << src;
    return -1;
  }

  // create outfile first to skip reading large files just no notice we cannot create dst
  std::string dst = argv[2];
  std::shared_ptr<arrow::io::FileOutputStream> outfile;
  PARQUET_ASSIGN_OR_THROW(
    outfile,
    arrow::io::FileOutputStream::Open(dst));
  LOG(INFO) << "open dst:" << dst << " for write";


  std::string path;
  auto fs = GetFileSystemFromUri(src, &path);

  auto dataset = GetDatasetFromPath(fs, format, path);
  auto scanner = GetScannerFromDataset(dataset, conf.projected_columns, conf.filter, conf.use_threads);
  LOG(INFO) << "loading data from src: " << src;
  auto table = GetTableFromScanner(scanner);
  LOG(INFO) << "src: " << src;
  LOG(INFO) << "num_columns: " << table->num_columns();
  LOG(INFO) << "num_rows:    " << table->num_rows();

  parquet::WriterProperties::Builder props_builder;
  props_builder.compression(parquet::Compression::SNAPPY);
  props_builder.version(parquet::ParquetVersion::PARQUET_2_0);

  // todo read those from env

  //props_builder.dictionary_pagesize_limit_(DEFAULT_DICTIONARY_PAGE_SIZE_LIMIT);
  //write_batch_size_(DEFAULT_WRITE_BATCH_SIZE),
  // max_row_group_length_(DEFAULT_MAX_ROW_GROUP_LENGTH),
  // pagesize_(kDefaultDataPageSize),
  //created_by_(DEFAULT_CREATED_BY)

  std::shared_ptr<parquet::WriterProperties> props = props_builder.build();

  LOG(INFO) << "saving dst";
  PARQUET_THROW_NOT_OK(
      parquet::arrow::WriteTable(*table, arrow::default_memory_pool(), outfile, ROW_GROUP_SIZE, props));
  LOG(INFO) << "done";
  outfile->Close();
  outfile.reset();

  LOG(INFO) << "check new stat";
  {
    std::unique_ptr<parquet::ParquetFileReader> reader = parquet::ParquetFileReader::OpenFile(dst);
    auto meta = reader->metadata();

    LOG(INFO) << "num_columns          " << meta->num_columns(),
    LOG(INFO) << "num_schema_elements  " << meta->num_schema_elements();
    LOG(INFO) << "num_rows             " << meta->num_rows();
    LOG(INFO) << "num_row_groups       " << meta->num_row_groups();
    LOG(INFO) << "avg row / row_groups " << meta->num_rows() / meta->num_row_groups();
    //PrintSchema(reader->metadata()->schema()->schema_root().get(), std::cout);
  }

  return EXIT_SUCCESS;
}
