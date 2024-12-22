;; To build sambamba using a recent Guix:
;;
;;   guix build -f guix.scm
;;
;; To get a development container (inside emacs shell will work!)
;;
;;   guix shell -C -D -F -f guix.scm

(use-modules
  (srfi srfi-1)
  (ice-9 popen)
  (ice-9 rdelim)
  ((guix licenses) #:prefix license:)
  (guix packages)
  (guix utils)
  ;; (guix download)
  (guix git-download)
  (guix build-system gnu)
  (guix gexp)
  (gnu packages base)
  (gnu packages bash)
  (gnu packages bioinformatics) ; for samtools in sambamba
  (gnu packages build-tools) ; for meson
  (gnu packages compression)
  ;; (gnu packages curl)
  (gnu packages dlang)
  (gnu packages gcc)
  (gnu packages pkg-config)
  ;; (gnu packages perl)
  (gnu packages python)
  ;; (gnu packages ninja)
  ;; (gnu packages ruby)
  (gnu packages tls)
  (gnu packages version-control)
  )

(define %source-dir (dirname (current-filename)))

(define %git-commit
  (read-string (open-pipe "git show HEAD | head -1 | cut -d ' ' -f 2" OPEN_READ)))

(define-public sambamba-git
  "singleobj -wi -I. -I./BioD:./BioD/contrib/msgpack-d/src -g -J. -O3 -release -enable-inlining -boundscheck=off"
  (package
    (name "sambamba-git")
    (version (git-version "1.0.0" "HEAD" %git-commit))
    (source (local-file %source-dir #:recursive? #t))
    (build-system gnu-build-system)
    (arguments
     `(;; #:tests? #f  ;; we'll run tests
       #:make-flags
       (list
        "VERBOSE=1"
        (string-append "CC=" ,(cc-for-target))
        (string-append "PREFIX=" %output))
       #:phases
       (modify-phases %standard-phases
                      (delete 'configure)         ; no configure script
                      (add-before 'check 'patch-tests
                                  (lambda _
                                    (substitute* "contrib/shunit2-2.0.3/shunit2"
                                                 (("/bin/sh") (which "sh")))))
                      (add-before 'install 'make-bin-dir
                                  (lambda _
                                    (mkdir-p (string-append %output "/bin"))))
       )))
    (outputs '("out"     ; disable all checks for speed
               "debug"))
    (inputs
     `(("samtools" ,samtools) ; for pileup
       ("bcftools" ,bcftools) ; for pileup
       ;; ("meson" ,meson) ; for testing meson build system
       ;; ("ninja" ,ninja)
       ("pkg-config" ,pkg-config)
       ("lz4-static" ,lz4 "static")
       ("lz4" ,lz4)
       ("zlib-static" ,zlib "static")
       ("zlib" ,zlib) ; also for the static build we need the includes
       ;; ("zstd-lib" ,zstd "static")
       ;; ("zstd" ,zstd "lib") ; same
       ))
    (native-inputs
     `(("ldc" ,ldc)
       ("bash-minimal" ,bash-minimal) ; for sh in shunit2
       ("python" ,python) ; Needed for building htslib and sambamba
       ("which" ,which)
       ))
    (home-page "https://github.com/BioD/sambamba")
    (synopsis "Fast tool for working with SAM and BAM files written in D.")
    (description
     "Sambamba is a high performance modern robust and fast
tool (and library), written in the D programming language, for working
with SAM and BAM files.  Current parallelised functionality is
an important subset of samtools functionality, including view, index,
sort, markdup, and depth.")
    (license license:gpl2+)))

sambamba-git
