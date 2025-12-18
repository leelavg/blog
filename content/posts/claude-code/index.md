+++
title = "Opinions after test driving Claude Code"
date = 2025-12-13T16:21:45+05:30
path = "claude-code"
draft = true
[taxonomies]
tags = ["claude-code"]
+++

We can't help but notice all the voices for and against AI usage, I want to have a first hand experience of using AI in some form or other and having done that now I can document my understandings and opinions. As my blog is in a small corner and receives less traffic, documenting the notes would atleast help me in the future.

Before this exercise my understanding of AI is from reading a couple of books, trying out models using llama-box (on CPU), vLLM (w/ LMCache, NiXL on GPU) and AI4ICPS course which gives a holistic view of AI landscape and multiple blogs. Not used any web based AI chat except Gemini (company subscription), no ChatGPT yet, forgoed Cursor subscription and finally Claude Code (company subscription) CC hereafter.

My day job is to build and deliver software as a solution to meet customer needs, among others, designing and implementing solution via code is a major part which I believe CC can increasly help me in.

These are the 3 catagories of tasks I performed using CC which I'll be reflecting upon, verifiability column indicates how strong I can assert CC response against my domain knowledge. I'm not specifically sharing AGENT files as it mostly contain efficiency rules, like map the codebase before coming up with solution, when to stop etc and initial prompts contains mostly goals related to the problem category and a possible approach.

| Category | Language | Verifiability | Goal | Cost | Models | Review | Result |
|:---------|:---------|:--------------|:-----|-----:|:-------|:-------|:-------|
| Microshift HA | Golang | Medium | Bounded | $200 | O45, S45, H | Partial | [report.txt](https://github.com/leelavg/microshift-dsm/blob/81f25d/.claude/report.txt), [DSM](https://github.com/leelavg/microshift-dsm/blob/81f25d/docs/user/howto_ha.md), [USM](https://github.com/leelavg/microshift-usm/blob/901fb7/docs/dev-test.md) |
| Assignment | Python | Least | Unbound | $30 | S45, H | Partial | [report.txt](./report.txt) |
| Refactor | Golang | Most | Exact | $10 | S45, H | Full | Can't Share |

Models shorthands can be guessed, they mean O45 = Opus 4.5; S45 = Sonnet 4.5; H = Haiku. Let's go.

## On Planning

Not all tasks can be planned from start to end. When the statement is clear and complete, planning and implementation shines. When standing up a fresh cluster the design is to make first node as control plane which is bootstrapped. When HA is formed with 3 Control Planes (CPs) in total a reboot of Microshift in bootstrap node make etcd thinks it isn't part of HA. The plan and the fix was sound and the implementation worked without further iterations.

Irrespective of the language I usually spin up a interpreter if one is available and verify my logic along with semantices is correct, you can argue unit test can help here. This exact verification in chunks greatly boost the plan feasibility and effectiveness. As the machine works on probability you'll only get likely solutions, a perfect plan was written and probably the lenghtiest  which is based on a certain flag availability on `ovnctl` but it doesn't exist in reality, asking CC to check it's assumptions averted cost and rebuild time.

During a migration of kubernetes resources reconciliation (typical operator pattern) a new plan with controlling owner references was changed but even if it's tested in isolation it'll fail in actual deployment since there should only be single controlling owner references and your domain knowledge helps here before such a change meets the reviewers eyes.

Bottom line, plan generation and execution according to the requirement in the lines of existing code has a certain strength to it and at the same time, your domain knowledge and verifiability of central parts of the plan makes this exercise more fruitful and less error prone.

## On Control Loop

Humans need a break and at the same time be responsible for the deliverables, howerever AI doesn't need to be. We are accustomed to predictability unless you have UBs and a dozone other quirks which aren't hit day2day, but AI by nature very much context dependent like a cli with thousands of flags and each flag representing a piece of context.

Given all these, AI just chugs away with the info you provide without a break but it can't be held responsible for any breakage. Contrast that to the setting we work, making CC to debug an issue which was working a moment ago and banging my head to only find it ignoring a build arg or a failed upgrade because you shipped a half vetted implementation, no one but you'll be responsible. Do this in a loop and you'll be forced to take a break rather than you opting for one.

Be as systematic as possible, prove the correctness by scoping your work in chunks and not fall into the trap that there is a machine waiting on me and I need to be there to command it which can reverse the roles if the control loop is not followed judiciously.

## On Bigger Models

I don't know why, there is a subtle nature to Sonnet than it's bigger sibbling Opus, this is more evident in mind mapping the existing code and debugging a failure, even in plan mode Sonnect seems _good enough_. Irrespective of model don't expect CC to read your mind and magically come up with a solution that can only be understood by only reading between the lines.

For every change made it takes around 40 minutes to generate a build and for a day this cycle didn't change, I was only doing this async but only realized later why CC didn't suggest running unit tests following the same line of thought I discovered a fast path which reduced the build duration of changes to 5 minutes.

Your thinking and following the context from all the sessions increases your chances of achieving the target, irrespective of model you choose because as of know our knowledge is multiplicative in relation to CC if it's considered additive.

## On Compaction

The prime observation after compacting a conversation is the knowledge retained mainly corresponds to start of the session and the latest chat like a human would read through jumbled characters in a word, however the penalty is the delay caused by compaction effecting the flow but with an upside of being able to continue the conversation rather than clearing it and prepping the new session to make it usable.

I don't think we can't time it, if nearing the compaction falls into a near completion of the task better create a short summary and clear to start new session with the summary or else let it compact.

## On Annoyances

There is no doubt that great minds are at work in designing the UX and the feature delivery is like a speed run, despite all this, I don't have a slightest idea why they don't fix the spurious scrolling of entire conversation when the current plan/diff/question etc is more than the height of terminal window. I'm fine with even forgoing the conversation if it can ask to clear the screen when the text is about to overflow like listening on `SIGNWNCH` maybe. I can't stress enough the UX hit caused by this bug.

Forgetting an action even after multiple repeatitions (yes, it's already there in CLAUDE.md) is something that hit me hard to reason through. Two of the categories are working on two repos and more than often I want to be able to see the debugging sessions or commands run etc and so I use tmux, tell CC to use `tmux send-keys` and `capture-pane` with a benefit that it sleeps momentarily where I can follow what's happening and penalty of some extra turns with tmux commands is fine for me. However, the biggest annoyance in this is, CC not clearing the screen thereby capturing stale/older info and reparsing it with occassionally using `tail/head`. I had told multiple times to clear the screen and can use tmux commands to capture full pane after finding the length of content rather than a missed info with `tail/head` and capturing again.

This last one is partially one me, not checking the documentation I expected CC to generate manifests for kube-vpn which resulted in a lot of work scrapping docs to fix it, here by default CC should be validating it's assumptions against docs?

## On Subagents

I didn't explicitly create subagents but occasionally told Opus to delegate the non-planning taks to Sonnect, this worked to an extent making Opus to be in charge nearing it's compaction but in background Sonnet is making progress. However after a day usage of Opus and comparing the cost vs progress I settles on Sonnect with no subagents. Moreover I wasn't using MCPs as it may eat up the context window and not easily measurable uptick in cost reduction or quality.

## Conclusion

There is no summary, using CC didn't feel like tweaking a normal cli to run with a specific arg or a field to set while making an API request etc. You got to try it and set guardrails, rules and steer it as you see it fit for the task at hand. This is a start for me and I can neither help it's progress nor wish for it's demise, it is another specialized tool in the tool box use it while it lasts or until it surpases the need to be driven by a human?

I see this style of working is the generation of non templated code which is semantically correct and view the correctness is a coincidence given the context but confused whether to spend more on learning the tool and all the surrounding ecosystem which also increases the delegation to it when hitting a snag or do more learning of the domain to retain the context myself and use the tool for laser focus work rather than not using at all?
