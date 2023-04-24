(require 'ox-html)
(require 'ox-publish)

(require 'lox-mode)
(require 'nix-mode)

(defun org-html-htmlize-generate-css ()
  "Create the CSS for all font definitions in the current Emacs session.
Use this to create face definitions in your CSS style file that can then
be used by code snippets transformed by htmlize.
This command just produces a buffer that contains class definitions for all
faces used in the current Emacs session.  You can copy and paste the ones you
need into your CSS file.

If you then set `org-html-htmlize-output-type' to `css', calls
to the function `org-html-htmlize-region-for-paste' will
produce code that uses these same face definitions."
  (interactive)
  (unless (require 'htmlize nil t)
    (error "htmlize library missing.  Aborting"))
  (and (get-buffer "*html*") (kill-buffer "*html*"))
  (with-temp-buffer
    (let ((fl (face-list))
          (htmlize-css-name-prefix "org-")
          (htmlize-output-type 'css)
          f i)
      (pop fl) ;; MZ: added this line.
      (while (setq f (pop fl)
                   i (and f (face-attribute f :inherit)))
        (when (and (symbolp f) (or (not i) (not (listp i))))
          (insert (org-add-props (copy-sequence "1") nil 'face f))))
      (htmlize-region (point-min) (point-max))))
  (pop-to-buffer-same-window "*html*")
  (goto-char (point-min))
  (when (re-search-forward "<style" nil t)
    (delete-region (point-min) (match-beginning 0)))
  (when (re-search-forward "</style>" nil t)
    (delete-region (1+ (match-end 0)) (point-max)))
  (beginning-of-line 1)
  (when (looking-at " +") (replace-match ""))
  (goto-char (point-min)))

(setq org-id-locations-file "org-id-locations"
      org-publish-timestamp-directory "org-timestamps")

(setq mz/date-format "%B %e %Y"
      mz/date-time-format "%l:%M %p on %B %e %Y")

(add-to-list 'org-export-filter-timestamp-functions
             #'(lambda (timestamp backend _info)
                 (cond
                  ((org-export-derived-backend-p backend 'html)
                   (replace-regexp-in-string "&[lg]t;\\|[][]" "" timestamp)))))

(setq-default org-display-custom-times t)

(setq org-export-date-timestamp-format mz/date-format
      org-html-metadata-timestamp-format mz/date-format
      org-time-stamp-custom-formats `(,mz/date-format . ,mz/date-time-format))

(defun mz/org-source-link (plist)
  "Create a link to the Git repo source of the given page to go in
  the postamble navigation bar if the given page is not an
  auto-generated site-map."
  (let ((file-name (string-trim-left buffer-file-name "/build/source/")))
    (if (and (string-match-p "index.org" file-name)
             (not (string= "index.org" file-name)))
        ""
      (format "<a href=\"https://github.com/michzappa/dot-com/blob/master/%s\">Source</a>"
              file-name))))

(defun mz/nav-bar (plist)
  (format "<nav>
    <a href=\"/\">/</a>
    <a href=\"/posts/\">Posts</a>
    %s
    <span style=\"float: right;\">
      <a href=\"https://creativecommons.org/licenses/by-sa/4.0/\">CC BY-SA 4.0</a>
    </span>
  </nav>
  Published using <a href=\"/posts/publishing_this_site_with_emacs.html\"><code>emacs</code></a>."
          (mz/org-source-link plist)))

(setq org-html-postamble #'(lambda (plist) (mz/nav-bar plist)))

(defun mz/org-sitemap-format-entry (entry _style project)
  "Show the date of an ENTRY in the sitemap for PROJECT if one is
specified in the org file."
  (let ((title (org-publish-find-title entry project))
        (date  (org-publish-find-date entry project)))
    (if (equal date '(0 1 0 0))
        (format "[[file:%s][%s]]" entry title)
      (format "[[file:%s][%s]] %s" entry title
              (format-time-string "%Y-%m-%d" date)))))

(setq org-html-head "<link rel=\"stylesheet\" href=\"/assets/source.css\"/>
                     <link rel=\"stylesheet\" href=\"/assets/main.css\"/>"
      org-html-head-include-default-style nil
      org-html-head-include-scripts nil
      org-html-htmlize-output-type 'css)

(setq org-publish-project-alist
      `(("site" :components ("posts" "assets"))
        ("posts"
         :auto-sitemap t
         :base-directory "./org"
         :base-extension "org"
         :htmlized-source t
         :include ("../index.org")
         :publishing-directory "./public/posts"
         :publishing-function  org-html-publish-to-html
         :recursive t
         :section-numbers nil
         :sitemap-filename "index.org"
         :sitemap-format-entry mz/org-sitemap-format-entry
         :sitemap-title "Posts"
         :time-stamp-file nil
         :with-author nil
         :with-creator nil
         :with-date nil
         :with-title t
         :with-toc nil)
        ("assets"
         :base-directory "./assets"
         :base-extension "css"
         :publishing-directory "./public/assets"
         :publishing-function org-publish-attachment
         :recursive t)))

(org-publich "site")
