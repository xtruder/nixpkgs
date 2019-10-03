{ stdenv, fetchFromGitHub, fetchgit, fetchurl, git, cmake, pkgconfig
, openssl, boost, zlib }:

let
  sqlite3 = fetchurl {
    url = "https://www.sqlite.org/2018/sqlite-amalgamation-3260000.zip";
    sha256 = "0vh9aa5dyvdwsyd8yp88ss300mv2c2m40z79z569lcxa6fqwlpfy";
  };

  beast = fetchgit {
    url = "https://github.com/boostorg/beast.git";
    rev = "2f9a8440c2432d8a196571d6300404cb76314125";
    sha256 = "1n9ms5cn67b0p0mhldz5psgylds22sm5x22q7knrsf20856vlk5a";
    leaveDotGit = true;
    fetchSubmodules = false;
  };

  docca = fetchgit {
    url = "https://github.com/vinniefalco/docca.git";
    rev = "335dbf9c3613e997ed56d540cc8c5ff2e28cab2d";
    sha256 = "1yisdg7q2p9q9gz0c446796p3ggx9s4d6g8w4j1pjff55655805h";
    leaveDotGit = true;
    fetchSubmodules = false;
  };

  rocksdb = fetchgit rec {
    url = "https://github.com/facebook/rocksdb.git";
    rev = "v5.17.2";
    sha256 = "0pv4qrjqmf7xa47gg9j7fnsghyvx0l95jgq44qn4hwv31zdc117m";
    leaveDotGit = true;
    deepClone = true;
    fetchSubmodules = false;
  };

  lz4 = fetchgit rec {
    url = "https://github.com/lz4/lz4.git";
    rev = "v1.8.2";
    sha256 = "1niv553q60hwn95yflzmrqkp1046hrid13h0yr36lm4fjza21h9w";
    leaveDotGit = true;
    fetchSubmodules = false;
    postFetch = "cd $out && git tag ${rev}";
  };

  libarchive = fetchgit rec {
    url = "https://github.com/libarchive/libarchive.git";
    rev = "v3.3.3";
    sha256 = "165imgfmizpi4ffpiwfs8gxysn6lw3y1fxj5rga98filkl7hxs31";
    leaveDotGit = true;
    fetchSubmodules = false;
    postFetch = "cd $out && git tag ${rev}";
  };

  soci = fetchgit {
    url = "https://github.com/SOCI/soci.git";
    rev = "3a1f602b3021b925d38828e3ff95f9e7f8887ff7";
    sha256 = "0lnps42cidlrn43h13b9yc8cs3fwgz7wb6a1kfc9rnw7swkh757f";
    leaveDotGit = true;
    fetchSubmodules = false;
  };

  snappy = fetchgit rec {
    url = "https://github.com/google/snappy.git";
    rev = "1.1.7";
    sha256 = "1f0i0sz5gc8aqd594zn3py6j4w86gi1xry6qaz2vzyl4w7cb4v35";
    leaveDotGit = true;
    fetchSubmodules = false;
    postFetch = "cd $out && git tag ${rev}";
  };

  nudb = fetchgit rec {
    url = "https://github.com/CPPAlliance/NuDB.git";
    rev = "2.0.1";
    sha256 = "1n443y87nj44w4bmdj3w5jf33449mnmr3c06izlh66m9pzrlr1j4";
    leaveDotGit = true;
    fetchSubmodules = false;
    postFetch = "cd $out && git tag ${rev}";
  };

  protobuf = fetchgit rec {
    url = "https://github.com/protocolbuffers/protobuf.git";
    rev = "v3.6.1";
    sha256 = "0zl09q25ggfw95lakcs3mkq5pvsj17mx29b4nqr09g0mnbw9709c";
    leaveDotGit = true;
    fetchSubmodules = false;
    postFetch = "cd $out && git tag ${rev}";
  };

  google-test = fetchgit {
    url = "https://github.com/google/googletest.git";
    rev = "c3bb0ee2a63279a803aaad956b9b26d74bf9e6e2";
    sha256 = "0pj5b6jnrj5lrccz2disr8hklbnzd8hwmrwbfqmvhiwb9q9p0k2k";
    fetchSubmodules = false;
    leaveDotGit = true;
  };

  google-benchmark = fetchgit {
    url = "https://github.com/google/benchmark.git";
    rev = "5b7683f49e1e9223cf9927b24f6fd3d6bd82e3f8";
    sha256 = "0qg70j47zqnrbszlgrzmxpr4g88kq0gyq6v16bhaggfm83c6mg6i";
    fetchSubmodules = false;
    leaveDotGit = true;
  };
in stdenv.mkDerivation rec {
  pname = "rippled";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "ripple";
    repo = "rippled";
    rev = version;
    sha256 = "1r6b2x5d22130w3qh9cb4240yrk44imk5vnz4ziwfqwgw7138zkv";
  };

  hardeningDisable = ["format"];
  cmakeFlags = [
    "-Dstatic=OFF"
    "-DBOOST_LIBRARYDIR=${boost.out}/lib"
    "-DBOOST_INCLUDEDIR=${boost.dev}/include"
  ];

  nativeBuildInputs = [ pkgconfig cmake git ];
  buildInputs = [ openssl openssl.dev zlib ];

  preConfigure = ''
    export HOME=$PWD

    git config --global url."file://${beast}".insteadOf "https://github.com/vinniefalco/Beast.git"
    git config --global url."file://${docca}".insteadOf "https://github.com/vinniefalco/docca.git"
    git config --global url."file://${rocksdb}".insteadOf "https://github.com/facebook/rocksdb.git"
    git config --global url."file://${lz4}".insteadOf "${lz4.url}"
    git config --global url."file://${libarchive}".insteadOf "${libarchive.url}"
    git config --global url."file://${soci}".insteadOf "${soci.url}"
    git config --global url."file://${snappy}".insteadOf "${snappy.url}"
    git config --global url."file://${nudb}".insteadOf "${nudb.url}"
    git config --global url."file://${protobuf}".insteadOf "${protobuf.url}"
    git config --global url."file://${google-benchmark}".insteadOf "${google-benchmark.url}"
    git config --global url."file://${google-test}".insteadOf "${google-test.url}"

    substituteInPlace CMakeLists.txt --replace "URL https://www.sqlite.org/2018/sqlite-amalgamation-3260000.zip" "URL ${sqlite3}"
  '';

  doCheck = true;
  checkPhase = ''
    ./rippled --unittest
  '';

  meta = with stdenv.lib; {
    description = "Ripple P2P payment network reference server";
    homepage = https://ripple.com;
    maintainers = with maintainers; [ ehmry offline ];
    license = licenses.isc;
    platforms = [ "x86_64-linux" ];
  };
}
