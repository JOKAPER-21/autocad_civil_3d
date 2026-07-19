// ============================================
// BANK CUTTING TOOL v4 - DCL
// Top-to-bottom layout
// ============================================

bank_cutting : dialog {
  label = "Bank Cutting Tool";
  width = 28;

  : text {
    label = "From (BE, FT) - To (TOE, GL)";
    alignment = centered;
  }
  : row {
    : edit_box {
      key        = "height_val";
      label      = "H:";
      edit_width = 8;
      is_enabled = false;
    }
    : button {
      key    = "btn_height";
      label  = "Pick Height";
      width  = 12;
    }
  }

  spacer_1;

  : text {
    label = "From (TOE, GL) - To (Track)";
    alignment = centered;
  }
  : row {
    : edit_box {
      key        = "dist_val";
      label      = "D:";
      edit_width = 8;
      is_enabled = false;
    }
    : button {
      key    = "btn_dist";
      label  = "Pick Distance";
      width  = 12;
    }
  }

  spacer_1;

  : text {
    label = " Direction ";
    alignment = centered;
  }
  : row {
    fixed_width = true;
    alignment   = centered;
    : button {
      key   = "btn_up";
      label = "UP";
      width = 10;
    }
    : button {
      key   = "btn_dn";
      label = "DN";
      width = 10;
    }
  }

  spacer_1;

  : text {
    label = " Insert Block";
    alignment = centered;
  }
  : button {
    key       = "btn_pickme";
    label     = "PICK ME";
    width     = 10;
    alignment = centered;
  }

  spacer_1;

  : button {
    key       = "cancel";
    label     = "Close";
    width     = 10;
    alignment = centered;
    is_cancel = true;
  }
}
