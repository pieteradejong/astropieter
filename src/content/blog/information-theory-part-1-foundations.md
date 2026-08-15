---
title: 'Information Theory Meets Graph Theory: The Foundations'
description: 'Part 1: Building intuition for information theory, graph theory, and Bayesian thinking with practical Python examples.'
pubDate: 'Jan 15, 2024'
tags: ['information-theory', 'graph-theory', 'bayesian-stats', 'python', 'mathematics']
draft: true
series: 'Information Theory Meets Graph Theory and Bayesian Statistics'
seriesOrder: 1
seriesDescription: 'A comprehensive exploration of how information theory, graph theory, and Bayesian statistics intersect to solve real-world problems.'
---

# Introduction



## Why These Three Together?

Before diving into the technical details, let's understand why combining these fields is so powerful:

- **Information Theory** gives us tools to quantify uncertainty and measure information content
- **Graph Theory** provides frameworks for modeling relationships and network structures  
- **Bayesian Statistics** offers principled ways to update beliefs with new evidence

Together, they let us ask questions like: "How does information flow through a social network?" or "What's the most efficient way to detect anomalies in a complex system?"

## Information Theory: Measuring Surprise

Information theory, developed by Claude Shannon in the 1940s, fundamentally asks: "How much information does a message contain?" The key insight is that **rare events carry more information than common ones**.

### Entropy: The Foundation

The cornerstone concept is **entropy** - a measure of uncertainty or "surprise" in a system:

$$H(X) = -\sum_{i} p(x_i) \log_2 p(x_i)$$

Let's build intuition with Python:

<!-- ```python
import numpy as np
import matplotlib.pyplot as plt
from collections import Counter

def entropy(probabilities):
    """Calculate Shannon entropy of a probability distribution"""
    # Remove zero probabilities to avoid log(0)
    probs = np.array([p for p in probabilities if p > 0])
    return -np.sum(probs * np.log2(probs))

# Example 1: Fair coin (maximum uncertainty)
fair_coin = [0.5, 0.5]
print(f"Fair coin entropy: {entropy(fair_coin):.3f} bits")

# Example 2: Biased coin (less uncertainty) 
biased_coin = [0.9, 0.1]
print(f"Biased coin entropy: {entropy(biased_coin):.3f} bits")

# Example 3: Certain outcome (no uncertainty)
certain = [1.0, 0.0]
print(f"Certain outcome entropy: {entropy(certain):.3f} bits")
``` -->

**Key Insight**: Higher entropy = more uncertainty = more information needed to resolve the uncertainty.

### Mutual Information: Measuring Dependence

Mutual information quantifies how much knowing one variable tells us about another:

```python
def mutual_information(joint_probs):
    """Calculate mutual information from joint probability matrix"""
    joint = np.array(joint_probs)
    
    # Marginal probabilities
    p_x = np.sum(joint, axis=1)
    p_y = np.sum(joint, axis=0)
    
    mi = 0
    for i in range(joint.shape[0]):
        for j in range(joint.shape[1]):
            if joint[i,j] > 0:
                mi += joint[i,j] * np.log2(joint[i,j] / (p_x[i] * p_y[j]))
    
    return mi

# Example: Weather and ice cream sales
# Rows: Weather (sunny, rainy), Cols: Sales (high, low)
weather_sales = [[0.3, 0.1],   # Sunny: high sales, low sales
                 [0.1, 0.5]]   # Rainy: high sales, low sales

mi = mutual_information(weather_sales)
print(f"Weather-Sales mutual information: {mi:.3f} bits")
```

## Graph Theory: Modeling Relationships

Graph theory studies networks of connected objects. A graph consists of:
- **Nodes (vertices)**: The objects being studied
- **Edges**: The relationships between objects

### Building Graphs with NetworkX

```python
import networkx as nx
import matplotlib.pyplot as plt

# Create a simple social network
G = nx.Graph()

# Add nodes (people)
people = ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve']
G.add_nodes_from(people)

# Add edges (friendships)
friendships = [('Alice', 'Bob'), ('Bob', 'Charlie'), ('Charlie', 'Diana'), 
               ('Alice', 'Charlie'), ('Diana', 'Eve')]
G.add_edges_from(friendships)

# Visualize the network
plt.figure(figsize=(8, 6))
pos = nx.spring_layout(G, seed=42)
nx.draw(G, pos, with_labels=True, node_color='lightblue', 
        node_size=1000, font_size=12, font_weight='bold')
plt.title("Simple Social Network")
plt.show()

# Basic network properties
print(f"Number of nodes: {G.number_of_nodes()}")
print(f"Number of edges: {G.number_of_edges()}")
print(f"Average degree: {np.mean([d for n, d in G.degree()]):.2f}")
```

### Degree Distribution: Our First Connection

Here's where information theory meets graph theory. The **degree distribution** of a network tells us about its structure, and we can measure its entropy:

```python
# Calculate degree sequence
degrees = [d for n, d in G.degree()]
degree_counts = Counter(degrees)

# Convert to probabilities
total_nodes = len(degrees)
degree_probs = [count/total_nodes for count in degree_counts.values()]

# Calculate entropy of degree distribution
degree_entropy = entropy(degree_probs)
print(f"Degree distribution entropy: {degree_entropy:.3f} bits")
```

**What does this mean?** A high-entropy degree distribution suggests a more "random" or diverse network structure, while low entropy indicates more regularity.

## Bayesian Statistics: Updating Beliefs

Bayesian statistics provides a framework for updating our beliefs as we gather evidence. The fundamental equation is **Bayes' theorem**:

$$P(H|E) = \frac{P(E|H) \cdot P(H)}{P(E)}$$

Where:
- $P(H|E)$: Posterior probability (updated belief)
- $P(E|H)$: Likelihood (evidence given hypothesis)  
- $P(H)$: Prior probability (initial belief)
- $P(E)$: Evidence probability (normalization)

### A Simple Example: Network Anomaly Detection

Imagine we're monitoring a computer network and want to detect suspicious activity:

<!-- ```python
def bayesian_update(prior, likelihood, evidence):
    """Simple Bayesian update"""
    posterior = (likelihood * prior) / evidence
    return posterior

# Scenario: Unusual traffic pattern detected
prior_malicious = 0.01  # 1% of traffic is normally malicious
likelihood_pattern_given_malicious = 0.9  # 90% chance of pattern if malicious
likelihood_pattern_given_normal = 0.05    # 5% chance of pattern if normal

# Calculate evidence probability
evidence_prob = (likelihood_pattern_given_malicious * prior_malicious + 
                likelihood_pattern_given_normal * (1 - prior_malicious))

# Update belief
posterior_malicious = bayesian_update(
    prior_malicious, 
    likelihood_pattern_given_malicious, 
    evidence_prob
)

print(f"Prior probability of malicious traffic: {prior_malicious:.1%}")
print(f"Posterior probability after suspicious pattern: {posterior_malicious:.1%}")
``` -->

**Key Insight**: Even with strong evidence (90% likelihood), the posterior probability depends heavily on the prior. This is crucial for avoiding false positives in anomaly detection.

## Connecting the Dots: A Preview

We've now introduced the three foundational concepts:

1. **Information Theory**: Entropy quantifies uncertainty and information content
2. **Graph Theory**: Networks model relationships between entities
3. **Bayesian Statistics**: Principled belief updating with evidence

In the next posts, we'll explore how these concepts interweave:

- **Part 2**: How can we use entropy to characterize network structures?
- **Part 3**: What happens when information flows through networks via random walks?
- **Part 4**: How do Bayesian networks represent probabilistic relationships?
- **Part 5**: Real-world applications in social networks, fraud detection, and sensor fusion
- **Part 6**: Building complete systems that combine all three approaches

## Setting Up Your Environment

To follow along with future posts, you'll want these Python libraries:

```bash
pip install numpy scipy matplotlib networkx pandas jupyter
pip install plotly seaborn  # For advanced visualizations
pip install pymc  # For Bayesian modeling (we'll choose this over pgmpy)
```

## What's Next?

In Part 2, we'll dive deeper into the connection between information theory and graph theory. We'll explore how entropy can characterize different types of networks and what this tells us about their structure and function.

We'll work with real datasets and build intuition for concepts like:
- Entropy of degree distributions
- Information content in network motifs
- Surprisal in random vs. structured networks

The mathematical foundations we've built today will be the building blocks for increasingly sophisticated analyses.

---

*This is Part 1 of "Information Theory Meets Graph Theory and Bayesian Statistics" - a series exploring the intersection of these powerful mathematical tools. Use the navigation above and below to explore other posts in this series.*
