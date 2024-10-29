#--
# Copyright (c) 2004 David Heinemeier Hansson
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

begin
  require 'action_controller'
rescue LoadError
  # Action Pack is not already available, try RubyGems
  require 'rubygems'	
  require_gem 'actionpack', '>= 0.9.0'
end

$:.unshift(File.dirname(__FILE__) + "/action_mailer/vendor/")

require 'action_mailer/base'
require 'action_mailer/mail_helper'
require 'action_mailer/vendor/tmail'
require 'net/smtp'

ActionView::Base.class_eval { include MailHelper }

old_verbose, $VERBOSE = $VERBOSE, nil
TMail::Encoder.const_set("MAX_LINE_LEN", 200)
$VERBOSE = old_verbose