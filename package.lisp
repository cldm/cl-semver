(defpackage :cl-semver
  (:nicknames :semver)
  (:use :cl :esrap :named-readtables)
  (:export #:read-version-from-string
	   #:print-version
	   #:print-version-to-string
	   #:version
	   #:semantic-version
	   #:make-semantic-version
	   #:version-string-valid-p
	   #:version-major
	   #:version-minor
	   #:version-patch
	   #:version-pre-release
       #:version-pre-release-identifiers
	   #:version-build
	   #:version=
	   #:version==
	   #:version/=
	   #:version/==
	   #:version<
	   #:version<=
	   #:version>
	   #:version>=
	   #:enable-version-syntax
	   #:disable-version-syntax
       #:semver-syntax
	   #:versionp)
  (:documentation "cl-semver is a Common Lisp implementation of the Semantic Versioning Specification (http://semver.org/"))
