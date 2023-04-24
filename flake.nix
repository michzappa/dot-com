{
  description = "michzappa's web site, written and published with emacs.";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOs/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, ... }@inputs:
    with inputs;
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = (import nixpkgs { inherit system; });
      in rec {
        publisherEmacs = (pkgs.emacsWithPackages (epkgs:
          (with epkgs; [ htmlize lox-mode nix-mode racket-mode tuareg ])));

        devShell =
          pkgs.mkShell { buildInputs = with pkgs; [ publisherEmacs ]; };

        packages.site = pkgs.stdenv.mkDerivation {
          name = "michzappa-dot-com";
          src = self;
          buildInputs = [ publisherEmacs ];
          buildPhase = ''
            # Tangle the literate program file.
            emacs ./org/publishing_this_site_with_emacs.org --batch --funcall org-babel-tangle
            # Publish.
            emacs --batch --load publish.el --funcall mz/publish-site
          '';
          installPhase = ''
            cp -r public $out
          '';
        };

        defaultPackage = self.packages.${system}.site;
      });
}
