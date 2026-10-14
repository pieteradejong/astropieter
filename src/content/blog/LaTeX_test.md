---
title: 'LaTeX test'
description: 'Testing whether LaTeX mathematical markup works in an Astro blog post.'
pubDate: 'Oct. 30 2023'
tags: ['all', 'math']
# Unlisted: a rendering test, not an essay. Browser fixtures and test.sh exercise KaTeX.
draft: true
---
**What:** LaTeX is a markup language for mathematical notation, ubiquitous in academia and beyond.

**Why:** The examples below show how math can be readably displayed using LaTeX, as opposed to awkwardly inserting images, or using English-alphabet characters to describe things.

**How:** I learned LaTeX notation in high school and University, as do most. On this site, `remark-math` and `rehype-katex` render it.


Equality:
$$
a = b
$$

Integral:
$$
\int_{-\infty}^{\infty} e^{-x^2} = \sqrt{\pi}
$$

Shannon's Entropy:

$$
H(x) = \mathbb{E}_{X \sim P}[I(x)] = -\mathbb{E}_{X \sim P}[\log P(x)]
$$

Sigmoid function:

$$
\frac{1}{1 + \exp{-x}}
$$

Euler's identity:

$$
e^{i\pi} = -1
$$

Classic Greek alphabet:

$\alpha,  \beta, \gamma, \delta, \epsilon$

$\Gamma, \Pi, \Sigma$

