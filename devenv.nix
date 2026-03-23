{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/packages/
  # Install Hugo extended (includes Sass/SCSS support) + essentials
  packages = [ 
    pkgs.hugo
    pkgs.git
    pkgs.gnutar  # Required for Hugo's asset processing
  ];

  # https://devenv.sh/languages/
  languages.nix.enable = true;

  # https://devenv.sh/scripts/
  scripts = {
    hugo-serve.exec = ''
      echo "🚀 Starting Hugo dev server..."
      echo "   Site will be available at: http://localhost:1313"
      echo "   Press Ctrl+C to stop"
      echo ""
      hugo server -D --bind 0.0.0.0 --disableFastRender
    '';

    hugo-build.exec = ''
      echo "🔨 Building site with Hugo..."
      rm -rf public/
      hugo --minify
      echo "✅ Build complete. Output in ./public/"
    '';

    hugo-clean.exec = ''
      echo "🧹 Cleaning build artifacts..."
      rm -rf public/ resources/_gen/
      echo "✅ Clean complete"
    '';
  };

  # https://devenv.sh/tests/
  enterTest = ''
    hugo version
  '';

  # https://devenv.sh/shell-commands/
  enterShell = ''
    echo "🎉 Hugo dev environment activated!"
    echo ""
    echo "Available commands:"
    echo "  hugo-serve  - Start dev server with drafts (http://localhost:1313)"
    echo "  hugo-build  - Build production site to ./public/"
    echo "  hugo-clean  - Remove build artifacts"
    echo "  hugo        - Run Hugo directly"
    echo ""
    echo "Theme is in: ./themes/hugo-theme-stack/"
    echo "Content is in: ./content/"
    echo ""
    hugo version
  '';

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # See full reference at https://devenv.sh/reference/options/
}
