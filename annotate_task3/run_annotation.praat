error_invalid_char = 1
error_consecutive_splitter = 2
error_invalid_index = 3
error_duplicate_index = 4

name_tier_3$ = "pic-Hu"

dir$ = "."
path_data$ = "'dir$'/Sound"
path_tmp$ = "'dir$'/tmp"
path_output$ = "'dir$'/output"
file_index$ = "'path_tmp$'/index.csv"
file_log$ = "'path_tmp$'/log.csv"
file_transcription_tagged$ = "'path_tmp$'/transcription_tagged.txt"
file_track_checkbox$ = "'dir$'/track_checkbox.praat"
file_mark_overlap$ = "'dir$'/mark_overlap.praat"
file_checkbox_return$ = "'path_tmp$'/checkbox_return.txt"


@get_index: file_index$
df_index = get_index.df_index
@update_index

@get_log: file_log$
df_log = get_log.df_log

select df_index
	n_id = Get number of rows
for i to n_id
	select df_index
		id = Get value: i, "id"
		handle$ = Get value: i, "handle"
		has_data = Get value: i, "has_data"
		finished = Get value: i, "finished"

	if has_data == 0
		beginPause: "INFO"
			comment: "[INFO] There is no data for speaker_'id'."
		endPause: "OK", 1

		goto CONTINUE
	endif

	if finished == 1
		goto CONTINUE
	endif
	
	file_tg_child$ = "'path_output$'/'handle$'_child.TextGrid"
	file_output$ = "'path_output$'/'handle$'_output.csv"

	sound = Read from file: "'path_data$'/'id'/'handle$'.wav"
	tg_prompt = Read from file: "'path_data$'/'id'/'handle$'_prompt.TextGrid"
	tg_word = Read from file: "'path_data$'/'id'/'handle$'_kaldi.TextGrid"
	tg_picwise = Read from file: "'path_data$'/'id'/'handle$'_picwise.TextGrid"
	df_picwise = Read Table from comma-separated file: "'path_data$'/'id'/'handle$'_picwise.csv"
	df_prompt = Read Table from comma-separated file: "'path_data$'/'id'/'handle$'_prompt.csv"

	select df_index
		j_start = Get value: i, "idx_prompt"
	if j_start == 1
		select tg_picwise
			n_tier = Get number of tiers

		select tg_prompt
			plus tg_word
			tg_merged = Merge
		select sound
			plus tg_merged
			View & Edit

		beginPause: "Annotate for speaker_'id'."
			comment: "Select the tier belonging to the child."
			choice: "tier_child", 1
			for j to n_tier
				select tg_word
					tier_name$ = Get tier name: j
				option: tier_name$
			endfor
		clicked = endPause: "Start annotating", 1

		select tg_word
			tier_name_selected$ = Get tier name: tier_child
		for j to n_tier
			select tg_picwise
				tier_name_picwise$ = Get tier name: j
			if tier_name_picwise$ == tier_name_selected$
				tier_child_picwise = j
			endif
		endfor

		select tg_merged
			Remove

		select tg_word
			tg_word_child = Extract one tier: tier_child
		select tg_prompt
			plus tg_word_child
			tg_child_ = Merge
		select tg_word_child
			Remove
		select tg_picwise
			tg_picwise_ = Extract one tier: tier_child_picwise
		select tg_picwise_
			Duplicate tier: 1, 2, name_tier_3$
		select tg_picwise_
			tg_picwise__ = Extract one tier: 2
		select tg_picwise_
			Remove

		select tg_child_
			plus tg_picwise__
			tg_child = Merge
		select tg_child_
			plus tg_picwise__
			Remove
	else
		tg_child = Read from file: file_tg_child$
		select df_index
			tier_child$ = Get value: i, "tier_child"

		beginPause: "Annotate for speaker_'id'."
			comment: "Continue annotating for speaker_'id' from picture_task_'j_start'."
		clicked = endPause: "Continue annotating", 1
	endif

	select df_picwise
		df_child_ = Extract rows where column (text): "tier_name", "is equal to", tier_child$
	select df_child_
		df_child = Extract rows where column (text): "task", "is not equal to", ""
	select df_child_
		Remove

	select df_prompt
		## FIXME: for debug
		# n_prompt = 3
		n_prompt = Get number of rows
	for j from j_start to n_prompt
		select df_prompt
			prompt$ = Get value: j, "text"
			start_prompt = Get value: j, "start"
			end_prompt = Get value: j, "end"
		select df_child
			df_task = Extract rows where column (text): "task", "is equal to", prompt$
		select df_task
			len_df_task = Get number of rows
			start = Get value: 1, "start"
			end = Get value: len_df_task, "end"
			text_init$ = Get value: 1, "text"
			valid = Get value: 1, "valid"
		if valid == 1
			@annotate_single_participant
		else
			printline "[INFO] Speaker_'id' didn't say anything in 'prompt$'."
		endif

		select df_task
			Remove
		
		select tg_child
			Save as text file: file_tg_child$
		select df_index
			Set numeric value: i, "idx_prompt", j + 1
			Set string value: i, "tier_child", tier_child$
			Save as comma-separated file: file_index$
		select df_log
			Save as comma-separated file: file_log$
	endfor

	select df_index
		Set numeric value: i, "finished", 1
		Save as comma-separated file: file_index$
	
	select df_log
		df_output = Extract rows where column (number): "id", "equal to", id
	select df_output
		Save as comma-separated file: file_output$
		Remove
	
	beginPause: "INFO"
		comment: "[INFO] Annotation for speaker_'id' finished."
	endPause: "OK", 1

	select tg_child
		plus df_child
		Remove

	select sound
		plus tg_prompt
		plus tg_word
		plus tg_picwise
		plus df_picwise
		plus df_prompt
		Remove
	
	label CONTINUE
endfor

beginPause: "INFO"
	comment: "[INFO] No more data to annotate."
endPause: "OK", 1

select df_index
	plus df_log
	Remove


################################################################################
procedure get_index: .file_index$
	.has_index = fileReadable(.file_index$)
	if .has_index == 0
		.df_index = Create Table with column names: "df_index", 0, "id handle has_data finished idx_prompt tier_child"
	else
		.df_index = Read Table from comma-separated file: .file_index$
	endif
endproc


################################################################################
procedure update_index
	list_id = Create Strings as folder list: "list_id", path_data$
	n_id = Get number of strings
	for .ii to n_id
		select list_id
			id_cur$ = Get string: .ii
		
		select df_index
			n_id_exist = Get number of rows

		exist = 0
		for .jj to n_id_exist
			select df_index
				id_exist_cur$ = Get value: .jj, "id"

			if id_cur$ == id_exist_cur$
				exist = 1

				goto BREAK
			endif
		endfor
		
		label BREAK
		
		if exist == 0
			handle$ = "'id_cur$'_task3"
			select df_index
				Append row
				Set string value: n_id_exist+1, "id", id_cur$
				Set string value: n_id_exist+1, "handle", handle$
				## FIXME: check if has data
				Set numeric value: n_id_exist+1, "has_data", 1
				Set numeric value: n_id_exist+1, "finished", 0
				Set numeric value: n_id_exist+1, "idx_prompt", 1
				Set string value: n_id_exist+1, "tier_child", ""
		endif
	endfor
	
	select df_index
		n_id_exist = Get number of rows
	if n_id_exist > 0
		select df_index
			Save as comma-separated file: file_index$
	endif
	
	select list_id
		Remove
endproc


################################################################################
procedure get_log: .file_log$
	.has_log = fileReadable(.file_log$)
	if .has_log == 0
		.df_log = Create Table with column names: "df_log", 0, "id prompt transcription_asr start_asr end_asr transcription_hu start_hu end_hu sound_file"
	else
		.df_log = Read Table from comma-separated file: .file_log$
	endif
endproc


################################################################################
procedure annotate_single_participant
	go_to_step_1 = 0
	
	label STEP_1
	select sound
		plus tg_child
		tg_$ = selected$ ("TextGrid", 1)
		View & Edit

	editor TextGrid 'tg_$'
		Zoom... start-0.5 end+0.5
		if j > 1
			if go_to_step_1 == 0
				Play... start end
			else
				go_to_step_1 = 0
			endif
		endif
	endeditor

	beginPause: "Correct transcription for 'prompt$', speaker_'id'."
		str_show$ = "[Step 1] Adjust the boundaries and transcriptions for Tier 3 ('name_tier_3$') of current task."
		n_line = ceiling (length (str_show$) / 80)
		for l to n_line
			line$ = mid$ ("'str_show$'", 80 * (l - 1) + 1, 80)
			comment: "'line$'"
		endfor
	endPause: "Go to Step 2", 1
	
	select tg_child
		tg_modified = Extract one tier: 3
	select tg_modified
		df_modified = Down to Table: "no", 6, "yes", "no"
	select df_modified
		df_modified_ = Extract rows where column (number): "tmin", "greater than or equal to", start_prompt
	select df_modified
		Remove
	select df_modified_
		df_modified = Extract rows where column (number): "tmax", "less than or equal to", end_prompt
	select df_modified_
		Remove

	select df_modified
		len_df_modified = Get number of rows
	if len_df_modified == 0
		select df_log
			Append row
			n_row_log = Get number of rows
			Set numeric value: n_row_log, "id", id
			Set string value: n_row_log, "prompt", prompt$
			Set string value: n_row_log, "transcription_asr", text_init$
			Set numeric value: n_row_log, "start_asr", start
			Set numeric value: n_row_log, "end_asr", end
			Set string value: n_row_log, "sound_file", "'handle$'.wav"
	endif

	for k to len_df_modified
		select df_modified
			text$ = Get value: k, "text"
			t_min = Get value: k, "tmin"
			t_max = Get value: k, "tmax"
		
		@split_string: text$, " "
		len_transcription = split_string.len
		for l to len_transcription
			array_transcription$[l] = split_string.array$[l]
		endfor
		
		text_tagged$ = ""
		for l to len_transcription
			text_tagged$ = text_tagged$ + "  ('l')  "
			text_tagged$ = text_tagged$ + array_transcription$[l]
		endfor
		
		label STEP_2
		if k == 1
			beginPause: "Mark hesitations for 'prompt$', speaker_'id'."
				comment: "[Step 2] Mark hesitations."
				comment: "- Input index of position when you want to mark a hesitation."
				comment: "- Use comma (,) to split multiple indices (e.g., 2,4)."
				comment: "- Don't insert multple types of hesitations at one position."
				comment: "--------------------------------------------------------------------------------"
				n_line = ceiling (length (text_tagged$) / 80)
				for l to n_line
					line$ = mid$ ("'text_tagged$'", 80 * (l - 1) + 1, 80)
					comment: "'line$'"
				endfor
				comment: "--------------------------------------------------------------------------------"
				comment: ""
				comment: "[X]: filled pause (erm, uhm) between target words"
				text: "idx_x", ""
				comment: "[.]: short unfilled pause (less than or equal to a second)"
				text: "idx_d", ""
				comment: "[..]: long unfilled pause (more than a second)"
				text: "idx_dd", ""
			go_to_step_1 = endPause: "Go back to Step 1", "Confirm", 2
			if go_to_step_1 == 1
				select tg_modified
					Remove
				select df_modified
					Remove
				
				editor TextGrid 'tg_$'
					Close
				endeditor
				
				goto STEP_1
			endif
		else
			beginPause: "Mark hesitations for 'prompt$', speaker_'id'."
				comment: "[Step 2] Mark hesitations."
				comment: "- Input index of position when you want to mark a hesitation."
				comment: "- Use comma (,) to split multiple indices (e.g., 2,4)."
				comment: "- Don't insert multple types of hesitations at one position."
				comment: "--------------------------------------------------------------------------------"
				n_line = ceiling (length (text_tagged$) / 80)
				for l to n_line
					line$ = mid$ ("'text_tagged$'", 80 * (l - 1) + 1, 80)
					comment: "'line$'"
				endfor
				comment: "--------------------------------------------------------------------------------"
				comment: ""
				comment: "[X]: filled pause (erm, uhm) between target words"
				text: "idx_x", ""
				comment: "[.]: short unfilled pause (less than or equal to a second)"
				text: "idx_d", ""
				comment: "[..]: long unfilled pause (more than a second)"
				text: "idx_dd", ""
			endPause: "Confirm", 1
		endif
		
		if idx_x$ <> ""
			@check_input_char: idx_x$
			if check_input_char.return <> 0
				@gen_error_info: check_input_char.return
				@show_error_info: gen_error_info.error_info$

				goto STEP_2
			endif
		
			@split_string: idx_x$, ","
			n_x = split_string.len
			for l to n_x
				@check_index: split_string.array$[l], 1, len_transcription
				if check_index.return <> 0
					@gen_error_info: check_index.return
					@show_error_info: gen_error_info.error_info$
					
					goto STEP_2
				endif
			
				array_idx_x[l] = number (split_string.array$[l])
			endfor
		else
			n_x = 0
		endif
		
		if idx_d$ <> ""
			@check_input_char: idx_d$
			if check_input_char.return <> 0
				@gen_error_info: check_input_char.return
				@show_error_info: gen_error_info.error_info$

				goto STEP_2
			endif

			@split_string: idx_d$, ","
			n_d = split_string.len
			for l to n_d
				@check_index: split_string.array$[l], 1, len_transcription
				if check_index.return <> 0
					@gen_error_info: check_index.return
					@show_error_info: gen_error_info.error_info$
					
					goto STEP_2
				endif

				array_idx_d[l] = number (split_string.array$[l])
			endfor
		else
			n_d = 0
		endif
		
		if idx_dd$ <> ""
			@check_input_char: idx_dd$
			if check_input_char.return <> 0
				@gen_error_info: check_input_char.return
				@show_error_info: gen_error_info.error_info$

				goto STEP_2
			endif

			@split_string: idx_dd$, ","
			n_dd = split_string.len
			for l to n_dd
				@check_index: split_string.array$[l], 1, len_transcription
				if check_index.return <> 0
					@gen_error_info: check_index.return
					@show_error_info: gen_error_info.error_info$
					
					goto STEP_2
				endif
				
				array_idx_dd[l] = number (split_string.array$[l])
			endfor
		else
			n_dd = 0
		endif
		
		m = 1
		for l to n_x
			array_idx_hes[m] = array_idx_x[l]
			m = m + 1
		endfor
		for l to n_d
			array_idx_hes[m] = array_idx_d[l]
			m = m + 1
		endfor
		for l to n_dd
			array_idx_hes[m] = array_idx_dd[l]
			m = m + 1
		endfor
		@check_duplicate_index
		if check_duplicate_index.return <> 0
			@gen_error_info: check_duplicate_index.return
			@show_error_info: gen_error_info.error_info$
			
			goto STEP_2
		endif

		for l to len_transcription
			if l == 1
				array_transcription_tagged$[2 * l - 1] = ""
			else
				array_transcription_tagged$[2 * l - 1] = " "
			endif
			array_transcription_tagged$[2 * l] = array_transcription$[l]
		endfor

		for l to n_x
			if array_idx_x[l] == 1
				array_transcription_tagged$[2 * array_idx_x[l] - 1] = "[X] "
			else
				array_transcription_tagged$[2 * array_idx_x[l] - 1] = " [X] "
			endif
		endfor

		for l to n_d
			if array_idx_d[l] == 1
				array_transcription_tagged$[2 * array_idx_d[l] - 1] = "[.] "
			else
				array_transcription_tagged$[2 * array_idx_d[l] - 1] = " [.] "
			endif
		endfor

		for l to n_dd
			if array_idx_dd[l] == 1
				array_transcription_tagged$[2 * array_idx_dd[l] - 1] = "[..] "
			else
				array_transcription_tagged$[2 * array_idx_dd[l] - 1] = " [..] "
			endif
		endfor

		transcription_tagged$ = ""
		for l to len_transcription
			transcription_tagged$ = transcription_tagged$ + array_transcription_tagged$[2 * l - 1] + array_transcription_tagged$[2 * l]
		endfor
		
		@split_string: transcription_tagged$, " "
		len_transcription_tagged = split_string.len
		for l to len_transcription_tagged
			array_transcription_tagged$[l] = split_string.array$[l]
		endfor
		
		text_for_overlap$ = ""
		for l to len_transcription_tagged
			text_for_overlap$ = text_for_overlap$ + "  ('l')  "
			text_for_overlap$ = text_for_overlap$ + array_transcription_tagged$[l]
		endfor
		text_for_overlap$ = text_for_overlap$ + "  ('l')"
		
		line$ = ""
		for l to len_transcription_tagged
			# line$ = line$ + array_transcription_tagged$[l]
			line$ = line$ + replace$ (array_transcription_tagged$[l], "'", "_", 0)
			if l < len_transcription_tagged
				line$ = line$ + " "
			endif
		endfor
		writeFileLine: file_transcription_tagged$, line$
		
		for l to len_transcription_tagged
			cur_word$ = replace_regex$ (array_transcription_tagged$[l], "[A-Z]", "\L&", 0)
			cur_word$ = replace$ (cur_word$, "'", "_", 0)
			len_word = length (cur_word$)
			end_char$ = mid$ ("'cur_word$'", len_word, 1)
			if end_char$ == "."
				cur_word$ = mid$ ("'cur_word$'", 1, len_word - 1)
			endif
			
			if cur_word$ == "[x]"
				cur_word$ = "hes_filled"
			elsif cur_word$ == "[.]"
				cur_word$ = "hes_short"
			elsif cur_word$ == "[..]"
				cur_word$ = "hes_long"
			endif
			
			if l == 1
				writeFileLine: file_track_checkbox$, "array_checkbox['l'] = '", cur_word$, "_'l'", "'"
			else
				appendFileLine: file_track_checkbox$, "array_checkbox['l'] = '", cur_word$, "_'l'", "'"
			endif
		endfor

		runScript: file_mark_overlap$
		
		line$ = readFile$ (file_checkbox_return$)
		@split_string: line$, " "
		for l to len_transcription_tagged
			array_checkbox[l] = number (split_string.array$[l])
		endfor
		
		text_overlap_tagged$ = ""
		for l to len_transcription_tagged
			text_overlap_tagged$ = text_overlap_tagged$ + array_transcription_tagged$[l]
			if l < len_transcription_tagged
				text_overlap_tagged$ = text_overlap_tagged$ + " "
			endif

			if array_checkbox[l] == 1
				if l < len_transcription_tagged
					text_overlap_tagged$ = text_overlap_tagged$ + "[O] "
				else
					text_overlap_tagged$ = text_overlap_tagged$ + " [O]"
				endif
			endif
		endfor
		
		# beginPause: "Mark overlaps for 'prompt$', speaker_'id'."
		# 	comment: "[Step 3] Mark overlaps."
		# 	comment: "--------------------------------------------------------------------------------"
		# 	n_line = ceiling (length (text_for_overlap$) / 80)
		# 	for l to n_line
		# 		line$ = mid$ ("'text_for_overlap$'", 80 * (l - 1) + 1, 80)
		# 		comment: "'line$'"
		# 	endfor
		# 	comment: "--------------------------------------------------------------------------------"
		# 	
		# 	comment: ""
		# 	str_show$ = "A) If there is only one overlap, input the start and end positions of the overlap."
		# 	n_line = ceiling (length (str_show$) / 80)
		# 	for l to n_line
		# 		line$ = mid$ ("'str_show$'", 80 * (l - 1) + 1, 80)
		# 		comment: "'line$'"
		# 	endfor
		# 	comment: "[OS]: start index of the overlap"
		# 	text: "idx_os", ""
		# 	comment: "[OE]: end index of the overlap"
		# 	text: "idx_oe", ""
		# 	
		# 	comment: ""
		# 	str_show$ = "B) If there is more than one overlap, input the start and end position pairs for each overlap in the format '1,3;4,5'."
		# 	n_line = ceiling (length (str_show$) / 80)
		# 	for l to n_line
		# 		line$ = mid$ ("'str_show$'", 80 * (l - 1) + 1, 80)
		# 		comment: "'line$'"
		# 	endfor
		# 	text: "idx_o", ""
		# endPause: "Confirm", 1
		# 
		# for l to len_transcription_tagged
		# 	if l == 1
		# 		array_overlap_tagged$[2 * l - 1] = ""
		# 	else
		# 		array_overlap_tagged$[2 * l - 1] = " "
		# 	endif
		# 	array_overlap_tagged$[2 * l] = array_transcription_tagged$[l]
		# endfor
		# 
		# has_last = 0
		# if idx_o$ == ""
		# 	idx_os = number (idx_os$)
		# 	if idx_os == 1
		# 		array_overlap_tagged$[2 * idx_os - 1] = "[OS] "
		# 	elif idx_os > len_transcription_tagged
		# 		array_overlap_tagged$[2 * idx_os - 1] = " [OS]"
		# 		has_last = 1
		# 	else
		# 		array_overlap_tagged$[2 * idx_os - 1] = " [OS] "
		# 	endif
		# 	
		# 	idx_oe = number (idx_oe$)
		# 	if idx_oe == 1
		# 		array_overlap_tagged$[2 * idx_oe - 1] = "[OE] "
		# 	elif idx_oe > len_transcription_tagged
		# 		array_overlap_tagged$[2 * idx_oe - 1] = " [OE]"
		# 		has_last = 1
		# 	else
		# 		array_overlap_tagged$[2 * idx_oe - 1] = " [OE] "
		# 	endif
		# else
		# 	@split_string: idx_o$, ";"
		# 	n_o = split_string.len
		# 	for l to n_o
		# 		array_idx_o$[l] = split_string.array$[l]
		# 	endfor
		# 	
		# 	for l to n_o
		# 		@split_string: array_idx_o$[l], ","
		# 		idx_os = number (split_string.array$[1])
		# 		if idx_os == 1
		# 			array_overlap_tagged$[2 * idx_os - 1] = "[OS] "
		# 		elif idx_os > len_transcription_tagged
		# 			array_overlap_tagged$[2 * idx_os - 1] = " [OS]"
		# 			has_last = 1
		# 		else
		# 			array_overlap_tagged$[2 * idx_os - 1] = " [OS] "
		# 		endif
		# 		
		# 		idx_oe = number (split_string.array$[2])
		# 		if idx_oe == 1
		# 			array_overlap_tagged$[2 * idx_oe - 1] = "[OE] "
		# 		elif idx_oe > len_transcription_tagged
		# 			array_overlap_tagged$[2 * idx_oe - 1] = " [OE]"
		# 			has_last = 1
		# 		else
		# 			array_overlap_tagged$[2 * idx_oe - 1] = " [OE] "
		# 		endif
		# 	endfor
		# endif
		# 
		# text_overlap_tagged$ = ""
		# for l to len_transcription_tagged
		# 	text_overlap_tagged$ = text_overlap_tagged$ + array_overlap_tagged$[2 * l - 1] + array_overlap_tagged$[2 * l]
		# endfor
		# if has_last == 1
		# 	text_overlap_tagged$ = text_overlap_tagged$ + array_overlap_tagged$[2 * l - 1]
		# endif
		
		beginPause: "Annotate for 'prompt$', speaker_'id'."
			comment: "The final marked transcription for current interval is:"
			comment: "--------------------------------------------------------------------------------"
			n_line = ceiling (length (text_overlap_tagged$) / 80)
			for l to n_line
				line$ = mid$ ("'text_overlap_tagged$'", 80 * (l - 1) + 1, 80)
				comment: "'line$'"
			endfor
			comment: "--------------------------------------------------------------------------------"
			comment: ""
			comment: "You have the last chance to edit it:"
			text: "transcription_final", "'text_overlap_tagged$'"
		endPause: "Confirm", 1
		
		select tg_modified
			interval_idx = Get interval at time: 1, t_min + ((t_max - t_min) / 2)
		select tg_child
			Set interval text: 3, interval_idx, transcription_final$

		select df_log
			Append row
			n_row_log = Get number of rows
			Set numeric value: n_row_log, "id", id
			Set string value: n_row_log, "prompt", prompt$
			Set string value: n_row_log, "transcription_asr", text_init$
			Set numeric value: n_row_log, "start_asr", start
			Set numeric value: n_row_log, "end_asr", end
			Set string value: n_row_log, "transcription_hu", transcription_final$
			Set numeric value: n_row_log, "start_hu", t_min
			Set numeric value: n_row_log, "end_hu", t_max
			Set string value: n_row_log, "sound_file", "'handle$'.wav"
	endfor
	
	select tg_modified
		Remove
	select df_modified
		Remove
	
	editor TextGrid 'tg_$'
		Close
	endeditor
endproc


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


################################################################################
procedure check_input_char: .string$
	.return = 0
	
	if .string$ == ""
		goto RETURN_CHECK_INDEX_CHAR
	endif

	.len = length (.string$)
	for .ii to .len
		.is_valid_input = 0
		if mid$ (.string$, .ii, 1) == "0"
			.is_valid_input = 1
		elsif mid$ (.string$, .ii, 1) == "1"
			.is_valid_input = 1
		elsif mid$ (.string$, .ii, 1) == "2"
			.is_valid_input = 1
		elsif mid$ (.string$, .ii, 1) == "3"
			.is_valid_input = 1
		elsif mid$ (.string$, .ii, 1) == "4"
			.is_valid_input = 1
		elsif mid$ (.string$, .ii, 1) == "5"
			.is_valid_input = 1
		elsif mid$ (.string$, .ii, 1) == "6"
			.is_valid_input = 1
		elsif mid$ (.string$, .ii, 1) == "7"
			.is_valid_input = 1
		elsif mid$ (.string$, .ii, 1) == "8"
			.is_valid_input = 1
		elsif mid$ (.string$, .ii, 1) == "9"
			.is_valid_input = 1
		elsif mid$ (.string$, .ii, 1) == ","
			.is_valid_input = 1
		endif

		if .is_valid_input == 0
			.return = error_invalid_char

			goto RETURN_CHECK_INDEX_CHAR
		elsif .is_valid_input == 1
			.is_valid_input = 0
		endif
	endfor

	label RETURN_CHECK_INDEX_CHAR
endproc


################################################################################
procedure check_index: .string$, .idx_min, .idx_max
	.return = 0

	if .string$ == ""
		.return = error_consecutive_splitter

		goto RETURN_CHECK_INDEX
	endif
	
	.idx = number (.string$)
	if .idx < .idx_min
		.return = error_invalid_index
		
		goto RETURN_CHECK_INDEX
	endif
	
	if .idx > .idx_max
		.return = error_invalid_index
	endif
	
	label RETURN_CHECK_INDEX
endproc


################################################################################
procedure check_duplicate_index
	.return = 0

	for .ii from 2 to m - 1
		for .jj to .ii - 1
			if array_idx_hes[.ii] == array_idx_hes[.jj]
				.return = error_duplicate_index

				goto RETURN_CHECK_DUPLICATE_INDEX
			endif
		endfor
	endfor
	
	label RETURN_CHECK_DUPLICATE_INDEX
endproc


################################################################################
procedure gen_error_info: .error
	if .error == error_invalid_char
		.error_info$ = "[ERROR] Invalid characters detected in input. Only digits 0-9 and ',' are permitted."
	elsif .error == error_consecutive_splitter
		.error_info$ = "[ERROR] Input contains consecutive delimiters such as ',,'."
	elsif .error == error_invalid_index
		.error_info$ = "[ERROR] Index out of range."
	elsif .error == error_duplicate_index
		.error_info$ = "[ERROR] Duplicate indices found in the input."
	endif
endproc


################################################################################
procedure show_error_info: .error_info$
	beginPause: "ERROR"
		comment: "'.error_info$'"
		comment: "Please input again."
	endPause: "OK", 1
endproc

