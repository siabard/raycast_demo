((d-mode
  . ((eval . (progn
               (setq-local company-dcd--flags
                           (list
                            (concat "-I" (expand-file-name "~/.dub/packages/bindbc-sdl/1.5.2/bindbc-sdl/source"))
                            (concat "-I" (expand-file-name "~/.dub/packages/bindbc-common/1.0.5/bindbc-common/source"))
                            (concat "-I" (expand-file-name "~/.dub/packages/bindbc-loader/1.1.5/bindbc-loader/source"))
                            (concat "-I" (expand-file-name "./source"))))
               (setq-local company-dcd-compiler "ldc2")
               )))))
