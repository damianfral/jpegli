{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    let
      overlay = final: prev: {
        jpegli = final.stdenv.mkDerivation {
          pname = "jpegli";
          version = "0.12.0";
          src = self.outPath;

          nativeBuildInputs = with final; [ cmake ninja pkg-config ];

          buildInputs = with final; [
            libpng
            giflib
            lcms2
            libhwy
            libjpeg_turbo
          ];

          cmakeFlags = [
            "-GNinja"
            "-DCMAKE_SKIP_BUILD_RPATH=ON"
            "-DJPEGLI_ENABLE_TOOLS=ON"
            "-DJPEGLI_ENABLE_MANPAGES=OFF"
            "-DJPEGLI_ENABLE_DOXYGEN=OFF"
            "-DJPEGLI_ENABLE_BENCHMARK=OFF"
            "-DJPEGLI_ENABLE_FUZZERS=OFF"
            "-DJPEGLI_ENABLE_DEVTOOLS=OFF"
            "-DJPEGLI_ENABLE_JPEGLI_LIBJPEG=OFF"
            "-DJPEGLI_ENABLE_JNI=OFF"
            "-DJPEGLI_ENABLE_OPENEXR=OFF"
            "-DJPEGLI_ENABLE_SJPEG=OFF"
            "-DBUILD_TESTING=OFF"
            "-DJPEGLI_FORCE_SYSTEM_HWY=ON"
            "-DJPEGLI_FORCE_SYSTEM_LCMS2=ON"
            "-DJPEGLI_BUNDLE_LIBPNG=OFF"
          ];

          preConfigure = ''
            mkdir -p third_party/libjpeg-turbo
            cp -v ${final.lib.getDev final.libjpeg_turbo}/include/jconfig.h third_party/libjpeg-turbo/jconfig.h.in
            cp -v ${final.lib.getDev final.libjpeg_turbo}/include/jpeglib.h third_party/libjpeg-turbo/
            cp -v ${final.lib.getDev final.libjpeg_turbo}/include/jmorecfg.h third_party/libjpeg-turbo/
          '';

          buildTargets = [ "cjpegli" "jpegli_threads" "jpegli_cms" ];

          installPhase = ''
            mkdir -p $out/bin $out/lib
            cp tools/cjpegli $out/bin/
            cp -d lib/libjpegli_threads.so* $out/lib/
            cp -d lib/libjpegli_cms.so* $out/lib/
            rpath=$(patchelf --print-rpath $out/bin/cjpegli)
            patchelf --set-rpath "$out/lib:$rpath" $out/bin/cjpegli
          '';

          meta = with final.lib; {
            description = "JPEG encoder/decoder library and cjpegli tool";
            homepage = "https://github.com/damianfral/jpegli";
            license = licenses.bsd3;
            platforms = platforms.unix;
            mainProgram = "cjpegli";
          };
        };
      };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
      in
      with pkgs; {
        packages.default = jpegli;

        devShells.default = mkShell {
          buildInputs = [
            clang
            cmake
            pkg-config
            gtest
            doxygen
            graphviz
            python3
            libclang.python
            libpng
            giflib
            lcms2
            ninja
          ];
          shellHook = ''
            export CC=clang
            export CXX=clang++
          '';
        };
      })
    // { overlays.default = overlay; };
}
