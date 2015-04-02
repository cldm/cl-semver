(in-package :semver)

(defclass version ()
  ()
  (:documentation "Library version"))

(defclass semantic-version (version)
  ((major :initarg :major
	  :accessor version-major
	  :initform (error "Provide the major version number")
	  :type integer
	  :documentation "The major version number")
   (minor :initarg :minor
	  :accessor version-minor
	  :initform (error "Provide the minor version number")
	  :type integer
	  :documentation "The minor version number")
   (patch :initarg :patch
	  :accessor version-patch
	  :initform (error "Provide the patch version number")
	  :type integer
	  :documentation "The patch (or micro) version number")
   (pre-release :initarg :pre-release
		:accessor version-pre-release
		:initform nil
		:type integer
		:documentation "The pre release version number")
   (build :initarg :build
	  :accessor version-build
	  :initform nil
	  :type integer
	  :documentation "The build version number"))
  (:documentation "Instances represent a full version according to the semantic version specs (version 2.0.0-rc1 of the spec). http://semver.org/ . The main features of this class are validation and version comparison."))

(defun tuple< (t1 t2)
  (when (and t1 t2)
    (let ((v1 (first t1))
	  (v2 (first t2)))
      (or (< v1 v2)
	  (and (equalp v1 v2)
	       (tuple< (rest t1)
		       (rest t2)))))))

(defgeneric validate-version (version)
  (:documentation "Validate a version"))

(defmethod validate-version ((version semantic-version))
  (with-slots (major minor patch build pre-release) version
    (when (not (and (integerp major)
		    (or (zerop major)
			(plusp major))))
      (error "Invalid version major: ~A in ~A" major version))
    (when (not (and (integerp minor)
		    (or (zerop minor)
			(plusp minor))))
      (error "Invalid version minor: ~A in ~A" minor version))
    (when (not (and (integerp patch)
		    (or (zerop patch)
			(plusp patch))))
      (error "Invalid version patch: ~A in ~A" patch version))
    (when (and build
	       (not (ignore-errors (parse 'version-build build))))
      (error "Invalid version build: ~A in ~A" build version))
    (when (and pre-release
	       (not (ignore-errors (parse 'version-pre-release pre-release))))
      (error "Invalid version pre-release: ~A in ~A" pre-release version))
    T))

(defmethod validate-version ((version (eql :max-version)))
    t)

(defmethod validate-version ((version (eql :min-version)))
    t)

(defmethod validate-version (version)
    (error "Invalid version: ~A" version))

(defmethod initialize-instance :after ((version semantic-version) &rest initargs)
  (declare (ignore initargs))
  (validate-version version))

;; Version parser

(defrule spaces (+ #\ ))

(defrule decimal (+ (or "0" "1" "2" "3" "4" "5" "6" "7" "8" "9"))
  (:function (lambda (list)
	       (parse-integer (format nil "~{~A~}" list)))))

(defrule version-build (+ (or (or "0" "1" "2" "3" "4" "5" "6" "7" "8" "9")
			      (character-ranges (#\a #\z) (#\A #\Z) #\_ #\.)))
  (:text t))

(defrule version-pre-release (+ (or (or "0" "1" "2" "3" "4" "5" "6" "7" "8" "9")
				    (character-ranges (#\a #\z) (#\A #\Z) #\_ #\.)))
  (:text t))

(defrule version (and decimal 
                      (? (and #\. decimal))
                      (? (and #\. decimal))
		      (? (and #\- version-pre-release))
		      (? (and #\+ version-build)))
  (:function (lambda (match)
	       (destructuring-bind (major minor patch pre-release build) match
		 (make-semantic-version major 
					(or (and minor
						 (second minor))
					    0)
					(or (and patch 
						 (second patch))
					    0)
					(and pre-release
					     (second pre-release))
					(and build
					     (second build)))))))

(defun version-string-valid-p (string)
  "Validate a version string"
  (or (equalp string "latest")
      (not (null (ignore-errors (parse 'version string))))))

(defun read-version-from-string (string &optional (class 'semantic-version))
  "Parses a semantic version from a string"
  (when (typep string 'version)
    (return-from read-version-from-string string))
  (when (not (version-valid-p string))
    (error "Could not parse version string ~S" string))
  (when (equalp string "latest")
    (return-from read-version-from-string :max-version))
  (parse 'version string))

(defun print-version (version &optional stream)
  "Prints a version to a stream"
  (cond
    ((equalp version :max-version)
     (format stream "latest"))
    ((equalp version :min-version)
     (format stream "oldest"))
    (t
     (format stream "~A.~A.~A"
	     (version-major version)
	     (version-minor version)
	     (version-patch version))
     (when (version-pre-release version)
       (format stream "-~A" (version-pre-release version)))
     (when (version-build version)
       (format stream "+~A" (version-build version))))))

(defun print-version-to-string (version)
  "Prints a version to a string"
  (with-output-to-string (s)
    (print-version version s)))

(defmethod print-object ((version semantic-version) stream)
  (format stream "#v\"~A\"" (print-version-to-string version)))

(defun versionp (object)
  (typep object 'version))

;; Version comparison
(defgeneric version= (version1 version2)
  (:documentation "Version equality comparison"))

(defmethod version= (version1 version2)
  nil)

(defmethod version= ((version1 version) (version2 version))
  (and (equalp (version-major version1)
	       (version-major version2))
       (equalp (version-minor version1)
	       (version-minor version2))
       (equalp (version-patch version1)
	       (version-patch version2))
       (equalp (version-pre-release version1)
	       (version-pre-release version2))
       (equalp (version-build version1)
	       (version-build version2))))

(defgeneric version== (version1 version2)
  (:documentation "Version shallow equality comparison"))

(defmethod version== (version1 version2)
  nil)

(defmethod version== ((version1 version) (version2 version))
  (and (version= version1 version2)
       (equalp (version-pre-release version1)
	       (version-pre-release version2))
       (equalp (version-build version1)
	       (version-build version2))))

(defgeneric version/= (version1 version2)
  (:documentation "Version distinct comparison"))

(defmethod version/= (version1 version2)
  t)

(defmethod version/= ((version1 version) (version2 version))
  (not (version= version1 version2)))

(defgeneric version/== (version1 version2)
  (:documentation "Version shallow distinct comparison"))

(defmethod version/== (version1 version2)
  t)

(defmethod version/== ((version1 version) (version2 version))
  (not (version== version1 version2)))

(defgeneric version< (version1 version2)
  (:documentation "Version less than comparison"))

(defmethod version< ((version1 (eql :min-version)) version2)
  t)
(defmethod version< (version1 (version2 (eql :max-version)))
  t)
(defmethod version< ((version1 (eql :max-version)) version2)
  nil)
(defmethod version< (version1 (version2 (eql :min-version)))
  nil)
(defmethod version< ((version1 version) (version2 version))
  (tuple< (list (version-major version1)
		(version-minor version1)
		(version-patch version1))
	  (list (version-major version2)
		(version-minor version2)
		(version-patch version2))))

(defun version<= (version1 version2)
  "Version less or equal comparison"
  (or (version= version1 version2)
      (version< version1 version2)))

(defun version> (version1 version2)
  "Version greater than comparison"
  (not (version<= version1 version2)))

(defun version>= (version1 version2)
  "Version greater or equal comparison"
  (or (version= version1 version2)
      (version> version1 version2)))

(defun make-semantic-version (major minor patch &optional pre-release build)
  "Creates a semantic version"
  (make-instance 'semantic-version
		 :major major
		 :minor minor
		 :patch patch
		 :pre-release pre-release
		 :build build))

;; Reader syntax

(defvar *previous-readtables* nil)

(defun version-syntax-reader (stream subchar arg)
  (declare (ignore subchar arg))
  (read-version-from-string (read stream t)))

(defun %enable-version-syntax ()
  "Internal function used to enable reader syntax and store current
readtable on stack."
  (push *readtable*
        *previous-readtables*)
  (setq *readtable* (copy-readtable))
  (set-dispatch-macro-character #\# #\v #'version-syntax-reader)
  (values))

(defun %disable-version-syntax ()
  "Internal function used to restore previous readtable." 
  (if *previous-readtables*
    (setq *readtable* (pop *previous-readtables*))
    (setq *readtable* (copy-readtable nil)))
  (values))

(defmacro enable-version-syntax ()
  "Enable version reader syntax."
  `(eval-when (:compile-toplevel :load-toplevel :execute)
    (%enable-version-syntax)))

(defmacro disable-version-syntax ()
  "Restore readtable which was active before last call to
ENABLE-VERSION-SYNTAX. If there was no such call, the standard
readtable is used."
  `(eval-when (:compile-toplevel :load-toplevel :execute)
    (%disable-version-syntax)))

(defmethod make-load-form ((version version) &optional environment)
  (declare (ignore environment))
  (with-slots (major minor patch build pre-release)
      version
    `(make-instance 'semantic-version 
		    :major ,major
		    :minor ,minor
		    :patch ,patch
		    :build ,build
		    :pre-release ,pre-release)))
