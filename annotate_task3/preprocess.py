#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Nov 25 16:39:01 2023

@author: nanzheng
"""

import os
import numpy as np
import pandas as pd
import subprocess


list_prompt = [
    "picture_task_1",
    "picture_task_2",
    "picture_task_3",
    "picture_task_4",
    "picture_task_5",
    "picture_task_6",
    "picture_task_7",
    "picture_task_8",
    "picture_task_9",
    "picture_task_10",
    "picture_task_11",
    "picture_task_12",
    "picture_task_13"
    ]


def read_chronological_textgrid(file_input):
    """
    
    """
    
    with open(file_input, "r") as f_input:
        list_line = list(map(lambda x: x.rstrip("\n"), f_input.readlines()))
    for i, line in enumerate(list_line):
        if line == "":
            head = "\n".join(list_line[: i])
            i += 1
            break
    
    list_line = list_line[i: ]
    
    list_tier_name = []
    list_tier_idx = []
    list_start = []
    list_end = []
    list_text = []
    for i in range(0, len(list_line), 4):
        tier_name = list_line[i].split(":")[-1]
        line_ = list_line[i + 1].split(" ")
        tier = int(line_[0])
        start = float(line_[1])
        end = float(line_[2])
        text = list_line[i + 2][1: -1]
        
        list_tier_name.append(tier_name)
        list_tier_idx.append(tier)
        list_start.append(start)
        list_end.append(end)
        list_text.append(text)
    
    df_input = pd.DataFrame({
        "tier_name": list_tier_name,
        "tier_idx": list_tier_idx,
        "start": list_start,
        "end": list_end,
        "text": list_text
        })
    
    return df_input, head


def write_chronological_textgrid(df_output, file_output):
    """
    
    """
    
    start = np.inf
    end = 0
    list_line = []
    
    df_output = df_output.sort_values(by="start")
    
    df_tier = df_output[["tier_name", "tier_idx"]].drop_duplicates().sort_values(by="tier_idx")
    for i in range(len(df_tier)):
        tier_name = df_tier["tier_name"].values[i]
        start_ = df_output[df_output["tier_name"] == tier_name]["start"].min()
        end_ = df_output[df_output["tier_name"] == tier_name]["end"].max()
        
        line = "\"IntervalTier\" \"{}\" {} {}".format(tier_name, start_, end_)
        list_line.append(line)
        
        if start_ < start:
            start = start_
        if end_ > end:
            end = end_
    list_line.append("")
    
    line = """"Praat chronological TextGrid text file"
{} {}   ! Time domain.
{}   ! Number of tiers.""".format(start, end, len(df_tier))
    list_line = [line] + list_line
    
    for i in range(len(df_output)):
        tier_name = df_output["tier_name"].values[i]
        tier_idx = df_output["tier_idx"].values[i]
        start = df_output["start"].values[i]
        end = df_output["end"].values[i]
        text = df_output["text"].values[i]
        
        line = """! :{}
{} {} {}
"{}"
""".format(tier_name, tier_idx, start, end, text)
        list_line.append(line)
    
    with open(file_output, "w") as f_output:
        f_output.write("\n".join(list_line))
    
    return None


def merge_blank(df_input):
    """
    
    """
    
    df_blank = df_input[df_input["text"].isin(["sil", ""])]
    df_non_blank = df_input[~df_input["text"].isin(["sil", ""])]
    
    df_blank_merged = pd.DataFrame({})
    list_tier_idx = sorted(df_blank["tier_idx"].unique().tolist())
    for tier_idx in list_tier_idx:
        df_cur = df_blank[df_blank["tier_idx"] == tier_idx].sort_values(by="start")
        
        tier_name = df_cur["tier_name"].values[0]
        list_start = []
        list_end = []
        
        start = df_cur["start"].values[0]
        for i in range(1, len(df_cur)):
            if df_cur["end"].values[i - 1] == df_cur["start"].values[i]:
                pass
            else:
                list_start.append(start)
                list_end.append(df_cur["end"].values[i - 1])
                
                start = df_cur["start"].values[i]
        
        list_start.append(start)
        list_end.append(df_cur["end"].values[i])
        
        df_cur_merged = pd.DataFrame({
            "tier_name": tier_name,
            "tier_idx": tier_idx,
            "start": list_start,
            "end": list_end,
            "text": ""
            })
        df_blank_merged = pd.concat([df_blank_merged, df_cur_merged])
    
    df_output = pd.concat([df_non_blank, df_blank_merged]).sort_values(by="start")
    
    return df_output


def fill_blank(df_input, head):
    """
    
    """
    
    list_tier_name = []
    list_tier_idx = []
    list_start = []
    list_end = []
    list_text = []
    
    list_line = head.split("\n")
    for i, line in enumerate(list_line[3: ]):
        list_line_ = line.split(" ")
        tier_name = list_line_[1][1: -1]
        start = float(list_line_[2])
        end = float(list_line_[3])
        
        df_cur = df_input[df_input["tier_name"] == tier_name].sort_values(by="start")
        tier_idx = df_cur["tier_idx"].values[0]
        text = ""
        
        start_ = start
        end_ = df_cur["start"].values[0]
        if start_ < end_:
            list_tier_name.append(tier_name)
            list_tier_idx.append(tier_idx)
            list_start.append(start_)
            list_end.append(end_)
            list_text.append(text)
        
        for j in range(len(df_cur) - 1):
            start_ = df_cur["end"].values[j]
            end_ = df_cur["start"].values[j + 1]
            if start_ < end_:
                list_tier_name.append(tier_name)
                list_tier_idx.append(tier_idx)
                list_start.append(start_)
                list_end.append(end_)
                list_text.append(text)
        
        start_ = df_cur["end"].values[-1]
        end_ = end
        if start_ < end_:
            list_tier_name.append(tier_name)
            list_tier_idx.append(tier_idx)
            list_start.append(start_)
            list_end.append(end_)
            list_text.append(text)
            
    df_to_append = pd.DataFrame({
        "tier_name": list_tier_name,
        "tier_idx": list_tier_idx,
        "start": list_start,
        "end": list_end,
        "text": list_text
        })
    df_output = pd.concat([df_input, df_to_append]).sort_values(by="start")
    
    return df_output


def gen_picwise_transcription(file_prompt, file_word, file_output_tg, file_output_df, file_prompt_df, file_word_merged):
    """
    
    """
    
    df_prompt, _ = read_chronological_textgrid(file_prompt)
    df_word, head_word = read_chronological_textgrid(file_word)
    df_word = merge_blank(df_word)
    write_chronological_textgrid(df_word, file_word_merged)

    df_left = pd.DataFrame({})
    list_tier_idx = sorted(df_word["tier_idx"].unique().tolist())
    for i, tier_idx in enumerate(list_tier_idx):
        df_tier = df_word[df_word["tier_idx"] == tier_idx]
        tier_name = df_tier["tier_name"].values[0]
        
        df_left_ = pd.DataFrame({
            "tier_name": tier_name,
            "tier_idx": tier_idx,
            "task": list_prompt
            })
        df_left = pd.concat([df_left, df_left_]).reset_index(drop=True)
        
    list_tier_name = []
    list_tier_idx = []
    list_start = []
    list_end = []
    list_text = []
    list_task = []
    list_valid = []
    for prompt in list_prompt:
        start_prompt = df_prompt[df_prompt["text"] == prompt]["start"].values[0]
        end_prompt = df_prompt[df_prompt["text"] == prompt]["end"].values[0]
        
        df_cur_pic = df_word[(df_word["start"] >= start_prompt) & (df_word["end"] <= end_prompt)]
        df_cur_pic = df_cur_pic[~df_cur_pic["text"].isin(["", "sil"])]
        df_cur_pic = df_cur_pic.sort_values(by="start")
        
        if len(df_cur_pic) == 0:
            continue
        
        # count_seg = 0
        # tier_name = df_cur_pic["tier_name"].values[0]
        # tier_idx = df_cur_pic["tier_idx"].values[0]
        # idx_start = 0
        # for i in range(1, len(df_cur_pic)):
        #     if df_cur_pic["tier_idx"].values[i] == tier_idx:
        #         pass
        #     else:
        #         start = df_cur_pic["start"].values[idx_start]
        #         end = df_cur_pic["end"].values[i - 1]
        #         text = " ".join(df_cur_pic["text"].values[idx_start: i].tolist())
        #         if count_seg < 2:
        #             text = text[0].upper() + text[1: ]
                
        #         list_tier_name.append(tier_name)
        #         list_tier_idx.append(tier_idx)
        #         list_start.append(start)
        #         list_end.append(end)
        #         list_text.append(text)
        #         list_task.append(prompt)
        #         list_valid.append(int(1))
                
        #         count_seg += 1
        #         tier_name = df_cur_pic["tier_name"].values[i]
        #         tier_idx = df_cur_pic["tier_idx"].values[i]
        #         idx_start = i
        
        # if count_seg > 0:
        #     list_text[-1] = list_text[-1] + "."
            
        # start = df_cur_pic["start"].values[idx_start]
        # end = df_cur_pic["end"].values[-1]
        # text = " ".join(df_cur_pic["text"].values[idx_start: i + 1].tolist()) + "."
        # if count_seg < 2:
        #     text = text[0].upper() + text[1: ]
        
        # list_tier_name.append(tier_name)
        # list_tier_idx.append(tier_idx)
        # list_start.append(start)
        # list_end.append(end)
        # list_text.append(text)
        # list_task.append(prompt)
        # list_valid.append(int(1))
        
        list_tier_idx_unique = df_cur_pic["tier_idx"].unique().tolist()
        for i, tier_idx in enumerate(list_tier_idx_unique):
            df_cur_tier = df_cur_pic[df_cur_pic["tier_idx"] == tier_idx].sort_values(by="start")
            tier_name = df_cur_tier["tier_name"].values[0]
            start = df_cur_tier["start"].values[0]
            end = df_cur_tier["end"].values[-1]
            text = " ".join(df_cur_tier["text"].values.tolist()) + "."
            text = text[0].upper() + text[1: ]
            
            list_tier_name.append(tier_name)
            list_tier_idx.append(tier_idx)
            list_start.append(start)
            list_end.append(end)
            list_text.append(text)
            list_task.append(prompt)
            list_valid.append(int(1))
            
    df_output = pd.DataFrame({
        "tier_name": list_tier_name,
        "tier_idx": list_tier_idx,
        "start": list_start,
        "end": list_end,
        "text": list_text,
        "task": list_task,
        "valid": list_valid
        })
    df_output = df_output.sort_values(by="start")

    df_merged = df_left.merge(df_output, how="left", on=["tier_name", "tier_idx", "task"])
    df_merged["valid"] = df_merged["valid"].fillna(0)

    df_output = fill_blank(df_output, head_word)
    write_chronological_textgrid(df_output, file_output_tg)

    df_interval_idx = pd.DataFrame({})
    list_tier_idx = sorted(df_output["tier_idx"].unique().tolist())
    for tier_idx in list_tier_idx:
        df_tier = df_output[df_output["tier_idx"] == tier_idx]
        df_tier["interval_idx"] = [i + 1 for i in range(len(df_tier))]
        
        df_interval_idx = pd.concat([df_interval_idx, df_tier])
    df_interval_idx = df_interval_idx[["tier_name", "tier_idx", "task", "start", "end", "interval_idx"]]

    df_merged = df_merged.merge(df_interval_idx, how="left", on=["tier_name", "tier_idx", "task", "start", "end"])
    df_merged.to_csv(file_output_df, sep=",", index=False)
    
    df_prompt = df_prompt[~df_prompt["text"].isin(["", "sil"])]
    df_prompt = df_prompt.sort_values(by="start").reset_index(drop=True)
    df_prompt.to_csv(file_prompt_df, sep=",", index=False)
    
    return 0


if __name__ == "__main__":
    dir_ = os.path.abspath(".")
    path_data = "../goldilocks_Renata/data"
    path_tmp = "./tmp"
    path_output = "./Sound"
    file_index = "data_info.csv"
    
    list_file = os.listdir(path_data)
    list_id = []
    for file in list_file:
        if file[-4: ] == ".wav":
            list_id.append(file[: -4])
    
    list_id_valid = []
    list_file_wav = []
    list_file_prompt_tg = []
    list_file_word_tg = []
    for id_ in list_id:
        if "{}.wav".format(id_) in list_file:
            list_id_valid.append(int(id_.split("_")[0]))
            list_file_wav.append(os.path.join(path_data, "{}.wav".format(id_)))
        
            if "{}_prompt.TextGrid".format(id_) in list_file:
                list_file_prompt_tg.append(os.path.join(path_data, "{}_prompt.TextGrid".format(id_)))
            else:
                list_file_prompt_tg.append("")
            
            if "{}_kaldi.TextGrid".format(id_) in list_file:
                list_file_word_tg.append(os.path.join(path_data, "{}_kaldi.TextGrid".format(id_)))
            else:
                list_file_word_tg.append("")
    
    df_index = pd.DataFrame({
        "id": list_id_valid,
        "file_wav": list_file_wav,
        "file_prompt_tg": list_file_prompt_tg,
        "file_word_tg": list_file_word_tg,
        "has_prompt_tg": list(map(lambda x: int(x != ""), list_file_prompt_tg)),
        "has_word_tg": list(map(lambda x: int(x != ""), list_file_word_tg))
        })
    df_index = df_index.sort_values(by="id").reset_index(drop=True)
    
    if not os.path.exists(path_output):
        os.mkdir(path_output)
    
    list_file_picwise_tg = []
    list_has_picwise_tg = []
    for i in range(len(df_index)):
        if df_index["has_prompt_tg"].values[i] + df_index["has_word_tg"].values[i] < 2:
            file_picwise_tg = ""
            has_picwise_tg = 0
        else:
            file_prompt_tg = df_index["file_prompt_tg"].values[i]
            file_word_tg = df_index["file_word_tg"].values[i]
            id_ = df_index["id"].values[i]
            
            path_output_ = os.path.join(path_output, "{}".format(id_))
            if not os.path.exists(path_output_):
                os.mkdir(path_output_)
            
            file_picwise_tg = os.path.join(path_output_, "{}_task3_picwise.TextGrid".format(df_index["id"].values[i]))
            file_picwise_df = os.path.join(path_output_, "{}_task3_picwise.csv".format(df_index["id"].values[i]))
            file_prompt_df = os.path.join(path_output_, "{}_task3_prompt.csv".format(df_index["id"].values[i]))
            file_word_merged = os.path.join(path_output_, "{}_task3_kaldi.TextGrid".format(df_index["id"].values[i]))
            
            file_prompt_tg_ = os.path.join(os.path.abspath(path_output_), "{}_task3_prompt.TextGrid".format(df_index["id"].values[i]))
            str_cmd = "cp {} {}".format(os.path.abspath(file_prompt_tg), file_prompt_tg_)
            subprocess.call(str_cmd, shell=True)
            
            if not gen_picwise_transcription(file_prompt_tg, file_word_tg, file_picwise_tg, file_picwise_df, file_prompt_df, file_word_merged):
                has_picwise_tg = 1
            else:
                has_picwise_tg = 0
        
        list_file_picwise_tg.append(file_picwise_tg)
        list_has_picwise_tg.append(has_picwise_tg)
    
    df_index["file_picwise_tg"] = list_file_picwise_tg
    df_index["has_picwise_tg"] = list_has_picwise_tg
    df_index.to_csv(file_index, sep=",", index=False)
    
    