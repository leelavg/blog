+++
title = "Opinions after test driving Claude Code"
date = 2025-12-13T16:21:45+05:30
path = "claude-code"
[taxonomies]
tags = ["claude-code"]
+++

After spending $240 and navigating 40-minute build cycles while adding HA to Microshift as an exercise with Claude Code (CC), I’ve isolated two core points of AI-assisted development, i.e, the **coincidence of correctness** and the **asymmetry of responsibility**.

We can't help but notice all the voices for and against AI usage. I wanted firsthand experience using AI in a professional capacity, and having done that, I can now document my notes. As my blog is in a small corner and receives little traffic, documenting these notes will at least help me in the future.

Before this exercise my understanding of AI is from reading a couple of books in addition to multiple blogs, trying out models using llama-box (on CPU), vLLM (w/ LMCache, NIXL on GPU) and AI4ICPS course which gives a holistic view of AI landscape. I had not used any web based AI chat except Gemini (company subscription), no ChatGPT yet, forgo a Cursor subscription to settle on Claude Code (company subscription).

My day job is to build and deliver software solutions to meet customer needs. Designing and implementing solutions via code is a major part where I believe CC can increasingly help me.

## The Workload

These are the three categories of tasks I performed using CC. The **Verifiability** column indicates how strongly I can assert the CC response against my domain knowledge.

| Category | Language | Verifiability | Goal | Cost | Models | Review | Result |
|:---------|:---------|:--------------|:-----|-----:|:-------|:-------|:-------|
| Microshift HA | Golang | Medium | Bounded | $200 | O45, S45, H | Partial | [report.txt](https://github.com/leelavg/microshift-dsm/blob/81f25d/.claude/report.txt), [DSM](https://github.com/leelavg/microshift-dsm/blob/81f25d/docs/user/howto_ha.md), [USM](https://github.com/leelavg/microshift-usm/blob/901fb7/docs/dev-test.md) |
| Assignment | Python | Least | Unbound | $30 | S45, H | Partial | [report.txt](./report.txt) |
| Refactor | Golang | Most | Exact | $10 | S45, H | Full | Can't Share |

Model shorthands: **O45** = Opus 4.5; **S45** = Sonnet 4.5; **H** = Haiku.

## On Planning

Not all tasks can be planned from start to end. When the statement is clear and complete, planning and implementation shine. When standing up a fresh cluster, the design is to make the first node a bootstrapped control plane. When an HA is formed with three Control Planes (CPs), a reboot of Microshift in the bootstrap node makes etcd think it isn't part of the HA. The plan and the fix were sound, and the implementation worked without further iterations.

Irrespective of the language, I usually spin up an interpreter if one is available to verify my logic and semantics. This exact verification in chunks greatly boosts the plan's feasibility. As the machine works on probability, you'll only get "likely" solutions. One 'perfect' plan (the lengthiest) assumed `ovnctl` had a flag that doesn't exist. Asking CC to check its assumptions averted unnecessary costs and rebuild time.

During a migration of Kubernetes resources reconciliation, a new plan with controlling owner references was changed. Even if tested in isolation, it will fail in actual deployment since there should only be single controlling owner references. Your domain knowledge helps here before such a change meets the reviewer's eyes.

**Bottom line:** Plan generation and execution according to requirements have strength, but your domain knowledge and verifiability of central parts of the plan make this exercise more fruitful and less error prone.

## On Control Loop

Humans need breaks, but they are also responsible for deliverables. AI needs no breaks, but it cannot be held responsible for its work. We are accustomed to predictability, but AI is very much context dependent, like a CLI with thousands of flags where each flag represents a piece of context.

AI just chugs away with the info you provide, but it can't be held responsible for any breakage. Contrast that to our setting: if I use CC to debug an issue and it ignores a build arg or ships a half-vetted implementation, **no one but I will be responsible**. Do this in a loop, and you'll be forced to take a break rather than opting for one.

Be systematic. Prove correctness by scoping work in chunks. Do not fall into the trap of thinking the machine is waiting on you, if the control loop isn't followed judiciously, the roles can easily reverse.

## On Bigger Models

There is a subtle nature to Sonnet that differs from its bigger sibling, Opus. This is most evident in mapping existing code and debugging failures, even in plan mode, Sonnet seems _good enough_. Irrespective of the model, don't expect CC to read your mind and magically come up with a solution that can only be understood by reading between the lines.

For every change made, it took around 40 minutes to generate a build. For a day, this cycle didn't change as I was doing this asynchronously. I only realized later that CC hadn't suggested running unit tests. Following that line of thought, **I discovered a fast path which reduced the build duration of changes from 40 minutes to 5 minutes**.

Your thinking and following of the context across sessions increases your chances of success. Our knowledge is multiplicative in relation to CC, whereas the tool's own logic is often additive.

## On Compaction

The primary observation after a conversation compacts is that the knowledge retained mainly corresponds to the very start of the session and the very latest messages. It’s similar to how a human can quickly read through a word with jumbled middle characters as long as the first and last parts are intact, the "gist" remains.

The penalty is a noticeable delay during the compaction process which breaks the flow, but the upside is being able to continue the conversation without the overhead of manually prepping a new session.

You can't predict when compaction will hit. If you're close to finishing the task when it triggers, summarize and clear the session, otherwise, let it compact.

## On Annoyances

While great minds are designing the UX, I don't know why they haven't fixed the spurious scrolling of the entire conversation when a plan or diff is taller than the terminal window. I would even prefer if it asked to clear the screen when text is about to overflow (perhaps by listening on `SIGWINCH`). 

Forgetting an action even after multiple repetitions (despite it being in `CLAUDE.md`) is also difficult to reason through. I often use `tmux send-keys` and `capture-pane` so I can follow what’s happening while CC works. However, CC more than often fails to clear the screen, thereby capturing stale info and reparsing it using `tail/head`. I’ve had to tell it multiple times to clear the screen and capture the full pane instead of missing info.

This last one is partially on me: by not checking the documentation, I allowed CC to generate manifests for kube-vpn based on incorrect assumptions. This resulted in a significant amount of manual work scraping docs to fix the errors. It highlights a fundamental need, by default, CC should be validating its assumptions against official documentation rather than operating on "likely" patterns.

## On Subagents

I didn't explicitly create subagents, but I occasionally told Opus to delegate non-planning tasks to Sonnet. This worked to an extent, keeping Opus in charge while Sonnet made progress in the background. However, after a day of comparing cost versus progress, I settled on Sonnet without subagents for a better cost-to-progress ratio.

I wasn't using MCPs as it may eat up the context window and can't easily measure uptick in cost reduction or quality.

## Conclusion

There is no summary. Using CC didn't feel like tweaking a normal CLI with a specific arg or a field to set while making an API request. You have to try it, set guardrails, and steer it as you see fit for the task at hand. This is a start for me and I can neither stop its progress nor wish for its demise. It is another specialized tool in the toolbox and use it while it lasts.

Humans have the advantage of thousands of years of fine-tuning against physical reality, allowing us to transfer logic across domains instinctively. Machines are building their context one isolated pattern at a time, but they still lack that cross-domain 'grounding'. For now, we aren't just driving the machine, we are its link to a reality it hasn't lived in.

I see this style of working as non-templated code generation that is semantically correct, though I view that correctness as a coincidence given the context and so I'm confused whether should I spend more on learning the tool and its ecosystem to increase delegation when hitting a snag, or should I focus on learning the domain to retain the context myself and use the tool only for laser focused work rather than not using at all?
