(asdf:defsystem #:cl-semver
  :serial t
  :description "Semantic Version implementation"
  :author "Mariano Montone"
  :license "MIT"
  :depends-on (#:alexandria
               #:esrap
               #:cl-ppcre)
  :components ((:file "package")
	       (:file "semver")))
