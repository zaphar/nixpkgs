{ writeText, bazel, bazelTest, runLocal }:

let
  WORKSPACE = writeText "WORKSPACE" ''
    workspace(name = "our_workspace")
  '';

  pythonLib = writeText "lib.py" ''
    def foo():
      return 43
  '';

  pythonBin = writeText "bin.py" ''
    from lib import foo

    assert foo() == 43
  '';

  pythonBUILD = writeText "BUILD" ''
    py_library(
      name = "lib",
      srcs = [ "lib.py" ],
    )

    py_binary(
      name = "bin",
      srcs = [ "bin.py" ],
      deps = [ ":lib" ],
    )
  '';

  workspaceDir = runLocal "our_workspace" {} ''
    mkdir $out
    cp ${WORKSPACE} $out/WORKSPACE
    mkdir $out/python
    cp ${pythonLib} $out/python/lib.py
    cp ${pythonBin} $out/python/bin.py
    cp ${pythonBUILD} $out/python/BUILD.bazel
  '';

  testBazel = bazelTest {
    name = "bazel-test-builtin-rules";
    inherit workspaceDir;
    bazelPkg = bazel;
    bazelScript = ''
      ${bazel}/bin/bazel \
        run \
          --host_javabase='@local_jdk//:jdk' \
          //python:bin
    '';
  };

in testBazel
