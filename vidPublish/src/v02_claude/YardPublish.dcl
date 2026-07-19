//==========================================================================
// YardPublish.dcl
// Dialog box definition for the Yard Publish tool (AutoCAD Civil 3D 2026)
// Place this file in the SAME folder as YardPublish.lsp
//==========================================================================

yard_publish_dlg : dialog {
    label = "Yard Publish - Select Yard";

    : list_box {
        key = "yard_list";
        label = "Yard Names:";
        width = 55;
        height = 18;
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

    ok_cancel;
}
