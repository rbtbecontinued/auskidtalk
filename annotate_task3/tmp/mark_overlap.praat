file_transcription_tagged$ = "./transcription_tagged.txt"
file_checkbox_return$ = "./checkbox_return.txt"


line$ = readFile$ (file_transcription_tagged$)
@split_string: line$, " "
len_transcription_tagged = split_string.len
for l to len_transcription_tagged
	array_transcription_tagged$[l] = split_string.array$[l]
endfor

beginPause: "Mark overlaps."
	comment: "[Step 3] Mark overlaps."
	for l to len_transcription_tagged - 1
		if array_transcription_tagged$[l] == "[X]"
			boolean: "Hes_filled" + "_'l'", 0
		elsif array_transcription_tagged$[l] == "[.]"
			boolean: "Hes_short" + "_'l'", 0
		elsif array_transcription_tagged$[l] == "[..]"
			boolean: "Hes_long" + "_'l'", 0
		elsif array_transcription_tagged$[l] == "XXX"
			boolean: "Xxx" + "_'l'", 0
		else
			cur_word$ = array_transcription_tagged$[l]
			len_word = length (cur_word$)
			end_char$ = mid$ ("'cur_word$'", len_word, 1)
			if end_char$ == "."
				boolean: mid$ ("'cur_word$'", 1, len_word - 1) + "_'l'", 0
			else
				boolean: mid$ ("'cur_word$'", 1, len_word) + "_'l'", 0
			endif
		endif
	endfor
	cur_word$ = array_transcription_tagged$[l]
	len_word = length (cur_word$) - 1
	end_char$ = mid$ ("'cur_word$'", len_word, 1)
	if end_char$ == "."
		boolean: mid$ ("'cur_word$'", 1, len_word - 1) + "_'l'", 0
	else
		boolean: mid$ ("'cur_word$'", 1, len_word) + "_'l'", 0
	endif
endPause: "Confirm", 1

include track_checkbox.praat

line$ = ""
for l to len_transcription_tagged
	line$ = line$ + string$ (array_checkbox[l])
	if l < len_transcription_tagged
		line$ = line$ + " "
	endif
endfor
writeFileLine: file_checkbox_return$, line$


################################################################################
procedure split_string: .string$, .sep$
    .len = 0
    repeat
        .idx_sep = index (.string$, .sep$)
        if .idx_sep <> 0
            .value$ = left$ (.string$, .idx_sep - 1)
            .string$ = mid$ (.string$, .idx_sep + 1, 10000)
        else
            .value$ = .string$
        endif
        .len = .len + 1
        .array$[.len] = .value$
    until .idx_sep = 0
endproc

