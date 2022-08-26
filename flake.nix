{
  description = "OpenOCD Dev Snapshot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = {self, nixpkgs}: {
    defaultPackage.x86_64-linux =
      with import nixpkgs { system = "x86_64-linux"; };

      stdenv.mkDerivation rec {
        pname = "openocd";
        version = "0.11.0+dev-snapshot";

        src = fetchgit {
          url = "https://github.com/openocd-org/openocd.git";
          rev = "f77c919cf4dd25d3540bdef7d0bf60f5b84d5dd6";
          sha256 = "sha256-d23TRVAS9hpeUhaVHeZAId4WcE3oGTeObu7FoW4g3ck=";
          fetchSubmodules = true;
        };

        nativeBuildInputs = [ pkg-config which libtool automake autoconf ];

        buildInputs = [ hidapi libftdi1 libusb1 ]
          ++ lib.optional stdenv.isLinux libgpiod;

        preConfigure = ''
          SKIP_SUBMODULE=1 ./bootstrap
        '';

        configureFlags = [
          "--disable-werror"
          "--enable-jtag_vpi"
          "--enable-usb_blaster_libftdi"
          (lib.enableFeature (! stdenv.isDarwin) "amtjtagaccel")
          (lib.enableFeature (! stdenv.isDarwin) "gw16012")
          "--enable-presto_libftdi"
          "--enable-openjtag_ftdi"
          (lib.enableFeature (! stdenv.isDarwin) "oocd_trace")
          "--enable-buspirate"
          (lib.enableFeature stdenv.isLinux "sysfsgpio")
          (lib.enableFeature stdenv.isLinux "linuxgpiod")
          "--enable-remote-bitbang"
        ];

        NIX_CFLAGS_COMPILE = lib.optionals stdenv.cc.isGNU [
          "-Wno-error=cpp"
          "-Wno-error=strict-prototypes" # fixes build failure with hidapi 0.10.0
        ];

        postInstall = lib.optionalString stdenv.isLinux ''
          mkdir -p "$out/etc/udev/rules.d"
          rules="$out/share/openocd/contrib/60-openocd.rules"
          if [ ! -f "$rules" ]; then
              echo "$rules is missing, must update the Nix file."
              exit 1
          fi
          ln -s "$rules" "$out/etc/udev/rules.d/"
        '';

        meta = with lib; {
          description = "Free and Open On-Chip Debugging, In-System Programming and Boundary-Scan Testing";
          longDescription = ''
          OpenOCD provides on-chip programming and debugging support with a layered
          architecture of JTAG interface and TAP support, debug target support
          (e.g. ARM, MIPS), and flash chip drivers (e.g. CFI, NAND, etc.).  Several
          network interfaces are available for interactiving with OpenOCD: HTTP,
          telnet, TCL, and GDB.  The GDB server enables OpenOCD to function as a
          "remote target" for source-level debugging of embedded systems using the
          GNU GDB program.
          '';
          homepage = "https://openocd.sourceforge.net/";
          license = licenses.gpl2Plus;
          maintainers = with maintainers; [ bjornfor prusnak ];
          platforms = platforms.unix;
        };
      };
  };
}