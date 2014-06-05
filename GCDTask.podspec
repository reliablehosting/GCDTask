
Pod::Spec.new do |s|
  s.name         = "GCDTask"
  s.version      = "0.0.1"
  s.summary      = "NSTask with some GCD block syntactic sugar."
  s.homepage     = "https://github.com/reliablehosting/GCDTask"
  s.author       = { "Darvell Long" => "darvell@reliableunit.net" }
  s.source       = { :git => "https://github.com/reliablehosting/GCDTask.git" }
  s.license      = {
    :type => "MIT License",
    :text => <<-LICENSE
    Copyright (C) 2014 Reliablehosting.com

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    LICENSE
  }
  s.platform     = :osx
  s.source_files = '*.{h,m}'
  s.description  = <<-DESC
    GCDTask is a wrapper for NSTask that allows for handling input, output and error streams just by providing a block to handle it.
     DESC
end
