add_executable(example1 example1.cpp)
target_link_libraries(example1 ${ALL_LIBS})
INSTALL(TARGETS example1 RUNTIME DESTINATION bin)
