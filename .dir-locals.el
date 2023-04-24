((nil . ((eval . (progn
                   (setq-local compile-command "nix build --print-build-logs")
                   (setq-local org-link-file-path-type 'relative)
                   (add-hook 'org-mode-hook #'flyspell-mode))))))
