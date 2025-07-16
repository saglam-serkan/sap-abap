# ZCL_HTML_POPUP

`ZCL_HTML_POPUP` is an ABAP helper class that simplifies the creation and display of HTML popup windows in SAP GUI.
It supports headers, paragraphs, lists, buttons with parameters, callouts (such as warnings or info), tables, and monospaced text blocks. 

This class can be used to show messages, contextual help (such as F1 help on selection screen elements), or rich content in a clear and user-friendly format within the SAP GUI.

## Features

- Styled HTML content with built-in CSS
- Headers
- Paragraphs
- Ordered and unordered lists
- Markdown-like tables
- Preformatted (monospaced) text blocks
- Callout sections (info, warning, success, error, etc.)
- Progress bar
- Buttons with actions and parameter passing

## Methods Overview

| Method                         | Description                                    | Relevant HTML Element | Notes                                          |
|:-------------------------------|:-----------------------------------------------|:----------------------|:-----------------------------------------------|
| `clear_content`                | Clears previously added elements               |                       | Call this method before displaying a new popup |
| `append_header`                | Appends a header                               | `<h1>` to `<h6>`      ||
| `append_paragraph`             | Appends a paragraph                            | `<p>`                 ||
| `append_ordered_list`          | Appends a ordered list                         | `<ol>`                ||
| `append_unordered_list`        | Appends a unordered list                       | `<ul>`                ||
| `append_markdown_table`        | Appends a markdown formatted table             | `<table>`             ||
| `append_monospaced_text_block` | Appends a block of monospaced (code-like) text | `<pre>`               ||
| `append_progress_bar`          | Appends a progress bar                         | `<progress>`          ||
| `append_button`                | Appends a clickable button                     | `<input>`             ||
| `append_callout_paragraph`     | Appends a paragraph in a callout box           | `<div>`               ||
| `begin_callout`                | Starts a callout section                       | `<div>`               | Other methods add content inside; remember to call `end_callout` |
| `end_callout`                  | Ends a callout section                         |                       | Closes the `<div>`; must be called after `begin_callout` |
| `display`                      | Renders and shows the content as a popup       |                       ||
| `on_button_click`              | Handles button click events                    |                       | /!\ Not yet finished |

## Example Usage

```abap
DATA(html_popup) = NEW zcl_html_popup( ).

html_popup->append_header(
    header = 'HTML Popup'
    size   = '2'
  ).

html_popup->append_paragraph(
    'This is an HTML popup with a header and paragraph.'
  ).

html_popup->display(
    title = 'Title'
  ).
```

## Examples
[See other examples](examples/)
