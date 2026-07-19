//==========================================================================
// VidPublish.dcl
// Dialog box definition for the VID Publish tool (AutoCAD Civil 3D 2026)
// Place this file in the SAME folder as VidPublish.lsp
//==========================================================================

vid_publish_dlg : dialog {
    label = "VID Publish - Select Yard";

    : list_box {
        key = "yard_list";
        label = "Yard Names:";
        width = 55;
        height = 14;
        fixed_width = true;
        fixed_height = true;
        multiple_select = false;
    }

    : text {
        key = "target_preview";
        label = "";
        width = 55;
    }

    spacer;

    : edit_box {
        key = "cmd_text";
        label = "Commands (saved to drawing properties / Comments):";
        edit_width = 55;
    }

    spacer;

    : toggle {
        key = "pdf_check";
        label = "Generate PDF";
        value = "1";
    }

    spacer;

    ok_cancel;
}
