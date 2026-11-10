-- Click OK on Resolve's render modals, and nothing else:
--   "Render completed!"                   (every comp.Render raises one)
--   "WARNING! Render did not complete!"   (a failed render)
-- Text is matched on each static text's name AND value (Resolve exposes it inconsistently).
--
-- [localized UI, seen on Resolve Studio 21.1.0.14 / macOS / Chinese] Two things made this script a
-- silent no-op: it returned 0, the modal stayed up, and every later scripting call returned None
-- (GetCurrentPage), so each render had to be dismissed by hand.
--   * the button is localized. `click button "OK" of w` raises on a Chinese UI (确定); the raise is
--     swallowed by the enclosing `try`, so okN never increments and the window is never dismissed.
--     The button is now looked up by name (OK / Ok / ok / 确定 / 好), then falls back to the last
--     button of the window - still only on windows that carry a render text, never the main window.
--   * the completed text is one multi-line static text ("Render completed! Rendered Range: 30.0 to
--     30.0\nTotal Render Time: ..."), so the exact test `s is "Render completed!"` never fires.
--     It is now matched as a prefix, and the redundant `exists (static text ...)` probe is dropped.
-- Returns "<completed>|<failed>|<failure dialog text>;; ..."
on textsOf(w)
	set out to {}
	tell application "System Events"
		repeat with txtItem in (every static text of w)
			set vals to {}
			try
				set end of vals to name of txtItem
			end try
			try
				set end of vals to value of txtItem
			end try
			try
				set end of vals to description of txtItem
			end try
			repeat with v in vals
				try
					if contents of v is not missing value then
						set s to (contents of v) as text
						if s is not "" and out does not contain s then set end of out to s
					end if
				end try
			end repeat
		end repeat
	end tell
	return out
end textsOf

-- localized "OK": the usual names first, then the window's last button.
on okButtonOf(w)
	tell application "System Events"
		repeat with b in (every button of w)
			-- a button's name can be missing; compare as text so a raise cannot escape
			try
				set bn to (name of b) as text
				try
					if bn is "OK" or bn is "Ok" or bn is "ok" or bn is "确定" or bn is "好" then return b
				end try
			end try
		end repeat
		try
			return last button of w
		end try
	end tell
	return missing value
end okButtonOf

tell application "System Events"
	if not (exists process "Resolve") then return "0|0|"
	tell process "Resolve"
		set okN to 0
		set failN to 0
		set failText to ""
		repeat with w in (every window)
			try
				set isDone to false
				set isFail to false
				set joined to ""
				repeat with s in (my textsOf(w))
					set s to s as text
					if s starts with "Render completed" then set isDone to true
					if s contains "Render did not complete" then set isFail to true
					set joined to joined & s & " "
				end repeat
				if isDone or isFail then
					-- click the button by name; a hardcoded "OK" raises on a localized UI and the
					-- raise would be swallowed here, leaving the modal up and the count at 0
					set btn to my okButtonOf(w)
					if btn is not missing value then
						click btn
						if isFail then
							set failN to failN + 1
							set failText to failText & joined & ";; "
						else
							set okN to okN + 1
						end if
					end if
				end if
			end try
		end repeat
		return (okN as text) & "|" & (failN as text) & "|" & failText
	end tell
end tell
