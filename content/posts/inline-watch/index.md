+++
title = "A poor persons inline kubectl resource watch"
date = 2025-03-13T12:42:18+05:30
path = "inline-watch"
[taxonomies]
tags = ["productivity"]
+++

Even in a limited capacity I want to have the functionality to update kubectl resource watch inline rather than adding new line for every entry and looked for any small scripts/plugins that provides it, however finding no such existence (maybe I didn't look hard enough) I tried creating a small script and it's working for my purposes and sharing the same.

Rather than the script, I found the process worthwhile, ie, start simple and iterate till it is good enough but don't try to perfect everything. Here is the [link](https://github.com/leelavg/blog/issues/2#issuecomment-2720237764) to final result in action.

## Requirement

When a watch command is run, like `kubectl get pods -w` we want the newer line to replace older line if it exists and the assumption (compromise?) is we can use the first column for checking equality, only store incoming data as less as possible, with that the outline is:

1. read the input line by line and store the first space separate column as a key in a dictionary
2. the value for the key is a counter, if value already exists use ANSI escape sequences to position the cursor on old line and clear it
3. print the line and move the cursor to older position if required

## Implementation

The script is so small and inline comments would be enough. We can attach more bells and whistles if required to expand it till ROI is reasonable.

``` sh,linenos
#!/bin/bash
declare -A lines
num=0
while read -r; do
  key=$(awk '{printf $1}' <<<"$REPLY") # read by default stores the message in REPLY var
  test x$key = x && continue # skip empty lines
  val=${lines[$key]:-''}
  if test x$val = x; then
    # new line
    printf "%2s %s\n" "$num" "$REPLY" # just print, we are always in correct position for new entry
    lines[$key]=$((num++))
  else
    # old line
    echo -en "\033[$((num - val))A" # go up to the line identified by current key/name
    echo -en "\033[0K" # clear line from start to end
    printf "%2s %s\n" "$val" "$REPLY" # output the updated info
    echo -en "\033[$((num - val))B" # go down to where we came from
  fi
  sleep .1 # 100 ms for human eye to follow?
done
```

You can save above in a file (`inw`) and make it executable (`chmod +x inw`) and available in your `PATH` (perhaps `mv inw ~/.local/bin`), I added this to my `.bashrc` as a function and use it as `kubectl get pods -w | inw`

We'll follow with what we can't do and moreover, I've made this as a blog post rather than providing just a gist is to stress how small we can start, at-least this was an annoying problem for me and I thought someone else would solve this someday (like `kubectl` itself would've it) even partially.

## Limitations

If you've seen the recording it'll be obvious we have shortcomings in certain scenarios, ie., if the line occupies (wrapped) more than one row the script doesn't work properly.

## Known issues

If we run the command right after clearing screen, the functionality doesn't work properly and I don't have a solution for that.

## Extensions

These are some of items which would enhance the experiences and at the same time we need to decide whether it's worth the time vs gain.

1. Make it work for lines which are wrapped and spills over to next row(s)
2. Take an argument to remove lines with pod status as `Terminating` since in most of the cases they are deleted (or could be stuck in deletion as well)

We have `less` and `more` pagers, with certain options `less` can page horizontally but that'll strip ANSI escape sequences. Further, options to `less` such as `FSsXRr` and for `more` the options `csfn1000` would be a good exploration.

Drop a mail if there are some issues in the script which needs fixes.
