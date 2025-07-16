# HTML Popup

`ZCL_HTML_POPUP` is a helper class that simplifies the creation and display of HTML popup windows in SAP GUI. It supports headers, paragraphs, lists, buttons with parameters, callouts (such as warnings or info), tables, and monospaced text blocks. 

This class can be used to show messages, contextual help (such as F1 help on selection screen elements), or rich content in a clear and user-friendly format within the SAP GUI.

## Features

- Styled HTML content with built-in CSS
- Headers
- Paragraphs
- Ordered and unordered lists
- Tables
- Monospaced text blocks
- Callout sections (info, warning, success, error, etc.)
- Progress bar

## Methods Overview

| Method                         | Description                                  | Relevant HTML Element   | Notes                                           |
|:-------------------------------|:---------------------------------------------|:------------------------|:------------------------------------------------|
| `CLEAR_CONTENT`                | Clears all current content.                  |                         | Call this method before displaying a new popup  |
| `APPEND_HEADER`                | Appends a header element.                    | `<h1>` ... `<h6>`       |                                                 |
| `APPEND_PARAGRAPH`             | Appends a paragraph element.                 | `<p>`                   |                                                 |
| `APPEND_ORDERED_LIST`          | Appends an ordered list with list items.     | `<ol>`                  |                                                 |
| `APPEND_UNORDERED_LIST`        | Appends an unordered list with list items.   | `<ul>`                  |                                                 |
| `APPEND_TABLE_FROM_STRING_TAB` | Appends a table from delimited string table. | `<table>`               |                                                 |
| `APPEND_MONOSPACED_BLOCK`      | Appends a monospaced text block.             | `<pre>`                 |                                                 |
| `APPEND_PROGRESS_BAR`          | Appends a progress bar element.              | `<progress>`            |                                                 |
| `APPEND_BUTTON`                | Appends a clickable button element.          | `<input type="submit">` |                                                 |
| `APPEND_CALLOUT_PARAGRAPH`     | Appends a styled callout paragraph.          | `<div>`                 |                                                 |
| `BEGIN_CALLOUT`                | Starts a callout section.                    | `<div>`                 | Other methods append content inside; remember to call `END_CALLOUT` |
| `END_CALLOUT`                  | Ends the callout section.                    |                         | Closes the `<div>`; must be called after `BEGIN_CALLOUT`            |
| `DISPLAY`                      | Displays the popup.                          |                         |                                                                     |


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
[See all examples](examples/)
