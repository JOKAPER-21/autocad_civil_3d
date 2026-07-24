;;; ==================================================================================================
;;;  File Name   : SIF.lsp
;;;  Title       : Select & Import Files
;;;  Command     : SIF
;;;
;;;  Author      : Rishi
;;;  Creator     : Rishi
;;;  Version     : 01
;;;  Created     : 24-Jul-2026
;;;  Last Update : 24-Jul-2026
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  DESCRIPTION
;;; --------------------------------------------------------------------------------------------------
;;;  SIF (Select & Import Files) is an AutoLISP utility that imports one or more
;;;  DWG/DXF files into the active drawing using a single native Windows file
;;;  selection dialog with multi-select support.
;;;
;;;  Each imported file is:
;;;    • Inserted as a block
;;;    • Automatically exploded (supports nested blocks)
;;;    • Moved onto its own uniquely generated layer
;;;    • Cleaned up through an automatic drawing purge after import
;;;
;;;  The utility is designed for quickly consolidating multiple CAD drawings
;;;  while preserving clear layer organization and minimizing drawing clutter.
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  FEATURES
;;; --------------------------------------------------------------------------------------------------
;;;  ✔ Native Windows multi-file selection dialog
;;;      - Ctrl + Click or Shift + Click to select multiple files
;;;      - Supports both DWG and DXF files
;;;      - "All Files" option allows mixed selections
;;;
;;;  ✔ Automatic layer creation
;;;      Layer format:
;;;          <Sequence>_<Filename>_<CreationDate>
;;;
;;;      Example:
;;;          1_StationA_30.11.2026
;;;          2_Culvert_06.03.2025
;;;
;;;  ✔ Import workflow
;;;      • Inserts each drawing as a block reference
;;;      • Automatically explodes imported blocks
;;;      • Supports nested block explosion
;;;      • Forces every imported entity onto its generated layer
;;;      • Ignores original source drawing layers
;;;
;;;  ✔ Automatic numbering
;;;      • Detects existing numbered layers
;;;      • Continues numbering across multiple executions
;;;
;;;  ✔ Drawing cleanup
;;;      Automatically performs PURGE equivalent to:
;;;          • All purgeable items
;;;          • Zero-length geometry
;;;          • Empty text objects
;;;          • Orphaned data
;;;
;;;  ✔ Error handling
;;;      • Processes files independently
;;;      • Skips failed imports
;;;      • Continues importing remaining files
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  WORKFLOW
;;; --------------------------------------------------------------------------------------------------
;;;      1. Execute SIF
;;;      2. Select one or more DWG/DXF files
;;;      3. Layer is created automatically
;;;      4. Drawing is inserted
;;;      5. Block is exploded
;;;      6. Imported entities moved to generated layer
;;;      7. Repeat for remaining files
;;;      8. Perform automatic PURGE
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  REQUIREMENTS
;;; --------------------------------------------------------------------------------------------------
;;;      • AutoCAD / AutoCAD Civil 3D
;;;      • Visual LISP (vl-load-com)
;;;      • Windows PowerShell
;;;      • Windows Script Host (WScript.Shell)
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  DEPENDENCIES
;;; --------------------------------------------------------------------------------------------------
;;;      None
;;;
;;;      PowerShell is executed inline.
;;;      No external .ps1 files are created or required.
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  LOAD
;;; --------------------------------------------------------------------------------------------------
;;;      APPLOAD → SIF.lsp
;;;      or Drag & Drop SIF.lsp into AutoCAD
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  RUN
;;; --------------------------------------------------------------------------------------------------
;;;      Command:
;;;          SIF
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  NOTES
;;; --------------------------------------------------------------------------------------------------
;;;      • Supports recursive block explosion using SIF-EXPLODE-DEPTH.
;;;      • Increase SIF-EXPLODE-DEPTH if source drawings contain deeper
;;;        nested block structures.
;;;      • Invalid characters in layer names are automatically replaced.
;;;      • If a file creation date cannot be read, the current drawing date
;;;        is used as a fallback.
;;;
;;; --------------------------------------------------------------------------------------------------
;;;  COPYRIGHT
;;; --------------------------------------------------------------------------------------------------
;;;      © 2026 Rishi. All Rights Reserved.
;;;      License: Internal Use
;;; ==================================================================================================