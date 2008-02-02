#!/usr/local/bin/rebol -cs

REBOL []

;print "Content-type: text/plain^/"

do %json.r

cache-mode: true

cgi: system/options/cgi
query-string: cgi/query-string
params: make object! decode-cgi query-string

cache: %/tmp/rss-box/
make-dir cache
file: join cache enbase/base to-string checksum params/url 16

referrer: select cgi/other-headers "HTTP_REFERER"
if not none? referrer [
   log: join cache "access.log"
   referrers: either exists? log [ load log ] [ make block! 50 ]
   insert referrers referrer 
   save log copy/part referrers 50
]

either all [cache-mode exists? file (difference now modified? file) < 00:05] [
   source: read file
   comment [ FIXME: Conditional GET would be nice but it does not work this way:
      print "Status: 304 Not Modified"
      print join "Date: " to-idate (modified? file)
      print newline
      quit
   ]
] [
	if error? result: try [
      connection: open to-url params/url
      mime: connection/locals/headers/Content-Type
      source: copy connection
      close connection
      if none? any [ find source "<channel" find source "<header" ] [
         make error! "Incompatible document format." 
      ]
      if any [ none? source find source "<error>" ] [
         make error! "I am afraid, Dave."
      ]
      true
   ] [
  	   source: read %error.tmpl
	   replace source "${home}" "?"
	   replace/all source "${url}" params/url
	   replace source "${message}" replace/all get in disarm result 'arg1 "&" "&amp;"
	]
	write file source
]

data: make object! [
   box: read %box.tmpl
   image: read %image.tmpl
   input: read %input.tmpl
   item: read %item.tmpl
   date: read %date.tmpl
   link: read %link.tmpl
   param: params
   xml: source
   modified: to-idate (modified? file) 
]

print "Content-Type: text/javascript^/"
print rejoin ["var org = {p3k: " to-json data "};^/"]
print read %main.js
