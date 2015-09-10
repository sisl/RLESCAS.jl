# *****************************************************************************
# Written by Ritchie Lee, ritchie.lee@sv.cmu.edu
# *****************************************************************************
# Copyright ã 2015, United States Government, as represented by the
# Administrator of the National Aeronautics and Space Administration. All
# rights reserved.  The Reinforcement Learning Encounter Simulator (RLES)
# platform is licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License. You
# may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0. Unless required by applicable
# law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the specific language
# governing permissions and limitations under the License.
# _____________________________________________________________________________
# Reinforcement Learning Encounter Simulator (RLES) includes the following
# third party software. The SISLES.jl package is licensed under the MIT Expat
# License: Copyright (c) 2014: Youngjun Kim.
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED
# "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
# NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# *****************************************************************************

#requires python and python-levenshtein
using Gtk.ShortNames
import Gtk: GtkTextBufferLeaf, GtkTextViewLeaf

using PyCall

@pyimport Levenshtein as pyleven

const GTK_WRAP_CHAR = int32(1)

#String 1 is transformed into String 2

getops(s1::String, s2::String) = pyleven.editops(s1, s2)

function editops_vis(s1::String, s2::String)

  ops = getops(s1, s2)

  win = @Window()

  textbuffer1 = @TextBuffer()
  textview1 = @TextView()
  textbuffer2 = @TextBuffer()
  textview2 = @TextView()

  setproperty!(textbuffer1, :text, s1)
  setproperty!(textbuffer2, :text, s2)

  setproperty!(textview1, :buffer, textbuffer1)
  setproperty!(textview2, :buffer, textbuffer2)

  setproperty!(textview1, :wrap_mode, GTK_WRAP_CHAR)
  setproperty!(textview2, :wrap_mode, GTK_WRAP_CHAR)

  create_tags!(textbuffer1)
  create_tags!(textbuffer2)

  frame1 = @Frame("Source")
  frame2 = @Frame("Target")
  scroll = @ScrolledWindow()
  grid = @Grid

  push!(frame1, textview1)
  push!(frame2, textview2)
  grid[1, 1] = frame1
  grid[2, 1] = frame2
  push!(scroll, grid)
  push!(win, scroll)

  setproperty!(grid, :hexpand, true)
  setproperty!(scroll, :hexpand, true)
  setproperty!(frame1, :hexpand, true)
  setproperty!(frame2, :hexpand, true)
  setproperty!(textview1, :hexpand, true)
  setproperty!(textview2, :hexpand, true)

  showall(win)

  process_ops!(textbuffer1, textbuffer2, ops)

  win, grid, scroll, frame1, frame2, textview1, textview2
end

function process_ops!(textbuffer1::GtkTextBufferLeaf, textbuffer2::GtkTextBufferLeaf,
                      ops::Vector{Any})

  for (op, src, dst) in ops
    src += 1 #compensate for 0 indexing
    dst += 1 #compensate for 0 indexing

    if op == "insert"
      apply_tag!(textbuffer2, "Green", dst, dst + 1)
    elseif op == "delete"
      apply_tag!(textbuffer1, "Red", src, src + 1)
    elseif op == "replace"
      apply_tag!(textbuffer1, "Blue", src, src + 1)
      apply_tag!(textbuffer2, "Blue", dst, dst + 1)
    else
      error("op not recognized: $op")
    end
  end
end

function create_tags!(textbuf::GtkTextBufferLeaf)
  #tags
  Gtk.create_tag(textbuf, "Red", background="red",foreground="white")
  Gtk.create_tag(textbuf, "Green", background="green",foreground="white")
  Gtk.create_tag(textbuf, "Blue", background="blue",foreground="white")
end

function apply_tag!(textbuf::GtkTextBufferLeaf, tag::ASCIIString, start_index::Int64, end_index::Int64)
  Gtk.apply_tag(textbuf, tag, Gtk.GtkTextIter(textbuf, start_index), Gtk.GtkTextIter(textbuf, end_index))
end

function clear_tags!(textbuf::GtkTextBufferLeaf, start_index::Int64, end_index::Int64)
  Gtk.remove_all_tags(textbuf, Gtk.GtkTextIter(textbuf, start_index), Gtk.GtkTextIter(textbuf, end_index))
end

function editops_filevis(file1::String, file2::String)
  include("../clustering.jl") #only this function needs Clustering, so isolate it here for performance

  s1 = Clustering.extract_string(file1)
  s2 = Clustering.extract_string(file2)

  editops_vis(s1, s2)
end
