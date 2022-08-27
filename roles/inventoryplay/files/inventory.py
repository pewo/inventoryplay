#!/usr/bin/env python3
import os
import subprocess
import argparse
import pathlib
import re

debug = False

def read_all_file(dir):

    hash = {};
    if not dir:
        return hash

    try:
        isdir = os.path.isdir(dir)
    except Exception as e:
        print("Error checking status of a directory","error:",e)
        return hash

    if not isdir:
        return hash

    files = [];
    with os.scandir(dir) as it:
        for entry in it:
            if debug: print("entry:",entry)
            if not entry.is_file():
                continue

            if entry.name.startswith('.'):
                continue
           
            #basename = os.path.basename(entry.name)
            #files.append(basename)
            files.append(os.path.join(dir, entry.name))

    for file in files:
        array = [];
        if debug: print("file:",file)
        try:
             f = open(os.fsdecode(file), "r")
        except Exception as e:
            print("Error reading file", file, " error: ", e)
            continue
        else:
            for line in f:
                array.append(line.strip())

            f.close()
            hash[os.path.basename(file)] = array

    return hash

def get_all_playbooks(pb,hash):
    res = []

    if not pb:
        return res

    if debug: print("Searching for",pb,"in",hash)
    for target in hash:
        arr = hash[target]
        if len(arr):
            targetplay = arr[0]
            if debug: print("target:",target,"targetplay:",targetplay)
            if targetplay:
                if targetplay == pb:
                    if debug: print("found one")
                    res.append(target)
                    arr.pop(0)


    return res

def construct_runs(hash):
    playbook = []

    run = 0
    found = 1

    while found:
        found = 0
        run += 1

        for target in hash:
            if debug: print("target:",target)
            arr = hash[target]
            if not len(arr):
                continue

            pb = arr[0]

            if not pb:
                continue

            if debug: print("pb:",pb)

            arrlen = len(playbook)
            if debug: print("len:",arrlen,"run:",run)
            if arrlen < run:
                play = dict()
                play["playbook"]=pb
                play["targets"]= get_all_playbooks(pb, hash)

                playbook.append(play)
                found = 1

    return playbook


if __name__ == "__main__": 
    parser = argparse.ArgumentParser(description="inventoryplay")
    parser.add_argument('--directory','-d', required=True, type=pathlib.Path, help='playbook inventory')
    parser.add_argument('--inventory','-i', required=True, action='append', type=pathlib.Path, help='inventory')
    parser.add_argument('--debug', action='store_true', help='enable debug')
    args = parser.parse_args()
    directory = args.directory
    debug = args.debug
    inventory = args.inventory

    hash = read_all_file(directory)
    run = construct_runs(hash)
    for i in range(len(run)):
        print("run:",i)
        pb = run[i]["playbook"]
        targets = run[i]["targets"]
        cmd = "ansible-playbook " + pb
        for inv in inventory:
            cmd += " -i " + str(inv)

        target=""
        for t in targets:
            target += "," + t
        
        target = re.sub(r'(^,)','',target)

        cmd += " -l " + target
        print("cmd:",cmd)
        #if debug:
            #print("pb:", pb, "targets:", targets)

    #print("run main:", run)

