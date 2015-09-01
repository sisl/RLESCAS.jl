#requires python and python-levenshtein
using Gtk.ShortNames
import Gtk: GtkTextBufferLeaf, GtkTextViewLeaf

using PyCall

const DISPLAY_NCHARS = 200

@pyimport Levenshtein as pyleven

#String 1 is transformed into String 2

type EditOpsVis
  fullstring1::ASCIIString #entire string 1
  fullstring2::ASCIIString #entire string 2
  donestring1::ASCIIString #part that is done
  workstring1::ASCIIString #working piece
  current_pos::Int64 #current index in fullstring1
  displaystring1::ASCIIString #portion that is displaying
  displaystring2::ASCIIString #portion that is displaying
  textbuffer1::GtkTextBufferLeaf
  textbuffer2::GtkTextBufferLeaf
  textview1::GtkTextViewLeaf
  textview2::GtkTextViewLeaf
  currentpage::Int64 #current page displayed
  editops::Vector{Any} #Array of tuples (operation, srcind, dstind)
  current_op::Int64 #current op index
  state::Int64 #0=ready, 1=highlight edit

  EditOpsVis() = new()
end

function EditOpsVis(s1::String, s2::String)
  vis = EditOpsVis()

  vis.fullstring1 = s1
  vis.fullstring2 = s2
  vis.donestring1 = ""
  vis.workstring1 = s1
  vis.current_pos = 1
  vis.editops = getops(s1, s2)
  vis.textbuffer1 = @TextBuffer()
  vis.textview1 = @TextView()
  vis.textbuffer2 = @TextBuffer()
  vis.textview2 = @TextView()

  setproperty!(vis.textview1, :buffer, vis.textbuffer1)
  setproperty!(vis.textview2, :buffer, vis.textbuffer2)

  go_to_page(vis, 1)

  vis.current_op = 1
  vis.state = 0

  return vis
end

getops(s1::String, s2::String) = pyleven.editops(s1, s2)

function editops_vis(s1::String, s2::String)

  vis = EditOpsVis(s1, s2)

  win = @Window()
  g = @Grid()

  reset_button = @Button("Reset")
  next_button = @Button("Next")

  create_tags!(vis.textbuffer1)

  restart_id = signal_connect(reset_button, "clicked") do widget
    println(widget, " was clicked!")
    #clear_tags!(vis.textbuffer1)
    go_to_page(vis, 1)
  end

  next_id = signal_connect(next_button, "clicked") do widget
    println(widget, " was clicked!")

    try
      edit_step(vis)
    catch
      println("exception caught")
    end
  end

  setproperty!(g, :row_spacing, 15)
  g[1:2, 1] = vis.textview1
  g[1:2, 2] = vis.textview2
  g[1, 5] = reset_button
  g[2, 5] = next_button

  push!(win, g)
  showall(win)

  vis
end

update_text!(textbuf::GtkTextBufferLeaf, text::ASCIIString) = setproperty!(textbuf, :text, text)

function update_buffers!(vis::EditOpsVis)
  update_text!(vis.textbuffer1, vis.displaystring1)
  update_text!(vis.textbuffer2, vis.displaystring2)
end

function create_tags!(textbuf::GtkTextBufferLeaf)
  #tags
  Gtk.create_tag(textbuf, "Red", background="red")
  Gtk.create_tag(textbuf, "Green", background="green")
  Gtk.create_tag(textbuf, "Blue", background="blue")
end

function apply_tag!(textbuf::GtkTextBufferLeaf, tag::ASCIIString, start_index::Int64, end_index::Int64)
  Gtk.apply_tag(textbuf, tag, Gtk.GtkTextIter(textbuf, start_index), Gtk.GtkTextIter(textbuf, end_index))
end

function clear_tags!(textbuf::GtkTextBufferLeaf, start_index::Int64, end_index::Int64)
  Gtk.remove_all_tags(textbuf, Gtk.GtkTextIter(textbuf, start_index), Gtk.GtkTextIter(textbuf, end_index))
end

clear_tags!(vis::EditOpsVis) = clear_tags!(vis.textbuffer1, 1, length(vis.workstring1))

function go_to_page(vis::EditOpsVis, page::Int64)
  vis.currentpage = page
  vis.displaystring1 = vis.workstring1[getrange(DISPLAY_NCHARS, page, length(vis.workstring1))]
  vis.displaystring2 = vis.fullstring2[getrange(DISPLAY_NCHARS, page, length(vis.fullstring2))]

  update_buffers!(vis)
end

function getrange(display_nchars::Int64, page::Int64, maxchars::Int64)
  start_index = (page - 1) * display_nchars + 1
  end_index = start_index > maxchars ? -1 : min(start_index + display_nchars - 1, maxchars)

  return  start_index : end_index
end

findpage(display_nchars::Int64, current_pos::Int64) = div(current_pos, display_nchars) + 1

function compress_editops(ops::Vector{Any})

end

function edit_step(vis::EditOpsVis)

  if vis.current_op > length(vis.editops)
    return false #completed all ops
  end

  op, srcindex, dstindex = vis.editops[vis.current_op]
  srcindex += 1 #compensate for 0 indexing
  dstindex += 1 #compensate for 0 indexing

  if vis.state == 0 #ready
    #show highlight

    page = findpage(DISPLAY_NCHARS, length(vis.donestring1))
    go_to_page(vis, page) #go to page where edit occurs

    #skip to the next operation
    cur = vis.current_pos
    vis.donestring1 = string(vis.donestring1, vis.fullstring1[cur:srcindex - 1])
    cur = vis.current_pos = srcindex

    if op == "insert"
      #insert and highlight in green
      vis.donestring1 = string(vis.donestring1, vis.fullstring2[dstindex]) #insert
      vis.workstring1 = string(vis.donestring1, vis.fullstring1[cur:end])
      go_to_page(vis, vis.currentpage)
      apply_tag!(vis.textbuffer1, "Green", length(vis.donestring1), length(vis.donestring1) + 1)
    elseif op == "delete"
      #highlight text to be deleted in red
      apply_tag!(vis.textbuffer1, "Red", length(vis.donestring1) + 1, length(vis.donestring1) + 2)
    elseif op == "replace"
      #hightlight text to be replaced in blue
      apply_tag!(vis.textbuffer1, "Blue", length(vis.donestring1) + 1, length(vis.donestring1) + 2)
    else
      error("Operation not supported: $op")
    end
    vis.state = 1

  elseif vis.state == 1 #highlight edit
    cur = vis.current_pos

    if op == "insert"
      #make edit and advance cursor
      #nothing to do...
    elseif op == "delete"
      vis.workstring1 = string(vis.donestring1, vis.fullstring1[cur + 1:end])
      go_to_page(vis, vis.currentpage)
      vis.current_pos += 1
    elseif op == "replace"
      vis.donestring1 = string(vis.donestring1, vis.fullstring2[dstindex])
      vis.workstring1 = string(vis.donestring1, vis.fullstring1[cur + 1:end])
      go_to_page(vis, vis.currentpage)
      vis.current_pos += 1
    else
      error("Operation not supported: $op")
    end

    clear_tags!(vis)
    vis.state = 0
    vis.current_op += 1
  end

  return true
end
