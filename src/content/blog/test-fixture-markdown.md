---
title: 'Test fixture: Markdown and LaTeX'
description: 'Rendering fixture for tests/content.spec.ts. A draft, so it never ships.'
pubDate: 'Jan 01 2020'
tags: ['test']
draft: true
---

Fixture for `tests/content.spec.ts`. Every construct here has an assertion;
change one and update the other.

## Second-level heading

### Third-level heading

Text with **bold**, *italic*, ~~strikethrough~~ and `inline code`.

A [relative link](/about/) and an autolinked literal: https://example.com

- unordered one
- unordered two
  - nested item

1. ordered one
2. ordered two

- [x] done task
- [ ] open task

> A blockquote.

| Left | Right |
|------|------:|
| a    |     1 |
| b    |     2 |

```python
def entropy(p):
    return -sum(x * log2(x) for x in p if x > 0)  # $$ not math in code
```

A footnote reference.[^1]

---

![Fixture image alt text](/favicon.svg)

## Math

Inline math: $E = mc^2$ sits in the sentence.

Display math, delimiters on their own lines:

$$
\int_{-\infty}^{\infty} e^{-x^2}\,dx = \sqrt{\pi}
$$

$$
H(X) = -\sum_{i=1}^{n} p(x_i) \log_2 p(x_i)
$$

$$
\begin{pmatrix} a & b \\ c & d \end{pmatrix} \mathbb{R}^{2 \times 2}
$$

An escaped dollar is literal text: it costs \$5.

[^1]: The footnote text.
