//==========================================================================
// VidPublish.dcl
// Dialog box definition for the VID Publish tool (AutoCAD Civil 3D 2026)
// Place this file in the SAME folder as VidPublish.lsp
//==========================================================================

vid_publish_dlg : dialog {
    label = "VID Publish";

    : boxed_column {
        label = "Yard";
        : list_box {
            key = "yard_list";
            label = "";
            width = 58;
            height = 16;
            fixed_width = true;
            fixed_height = true;
            multiple_select = false;
        }
        : text {
            key = "target_preview";
            label = "";
            width = 58;
        }
    }

    spacer_1;

    : boxed_column {
        label = "Publish Options";

        : edit_box {
            key = "cmd_text";
            label = "Commands  (saved to drawing properties / Comments):";
            edit_width = 58;
        }

        spacer_1;

        : toggle {
            key = "pdf_check";
            label = "Generate PDF";
            value = "1";
        }

        : toggle {
            key = "newversion_check";
            label = "New Version";
            value = "0";
        }
    }

    spacer_1;

    ok_cancel;
}
