# 360 No Scope - AI Reinforcement Learning

A 2D medieval platformer where an AI agent learns to execute the perfect mid-air "360 no scope" shot using deep reinforcement learning.

## The Challenge

The player must jump off a cliff, fall through a canyon, and fire a single arrow at an enemy during a ~40 pixel precision window — all while falling at speed. The AI learns this entirely from scratch through trial and error, with zero human demonstrations.

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Game Engine | Godot 4.5 (.NET) |
| RL Algorithm | PPO (Proximal Policy Optimization) |
| ML Framework | Stable Baselines 3 / PyTorch |
| RL Plugin | Godot RL Agents |
| Model Export | ONNX Runtime |
| Language | GDScript + Python |

## How It Works

### Observation Space (what the AI sees)
- Relative X distance to enemy (normalized)
- Relative Y distance to enemy (normalized)
- Player's Y velocity (normalized)
- Ground contact (boolean)

### Action Space (what the AI can do)
- **Move**: left / right / none (discrete, 3 options)
- **Jump**: yes / no (discrete, 2 options)
- **Shoot**: yes / no (discrete, 2 options)

### Reward Structure

The reward function went through 10+ iterations. The final version:

| Event | Reward | Purpose |
|-------|--------|---------|
| One-shot kill | +3.0 | Ultimate goal |
| Multi-shot kill | +1.0 | Still good |
| Shooting while falling at enemy height (<40px) | +1.5 | Perfect timing |
| Shooting while falling near enemy (<80px) | +0.4 | Close timing |
| Being airborne | +0.02/frame | Encourage jumping |
| Airborne near enemy height | +0.05/frame | Encourage positioning |
| Moving right on ground | +0.005/frame | Move toward cliff |
| Standing on ground | -0.002/frame | Don't idle |
| Extra shots (>1) | -0.5 each | One shot only |
| Death / falling off map | -0.1 | Mild — encourages exploration |

### Training Setup
- 6 parallel game instances for faster sample collection
- `ent_coef = 0.005` to prevent premature convergence
- ~200K timesteps to convergence (~8 minutes)
- Final model size: 2KB (ONNX)

## Project Structure

```
360_No_Scope_rl2/
├── 360_No_Scope_rl2/          # Godot project
│   ├── Character/
│   │   ├── Movement.gd        # Player controller (AI/human toggle)
│   │   ├── ai.gd              # AI controller (obs, actions, rewards)
│   │   └── bullet.gd          # Projectile physics
│   ├── EnemySide/
│   │   └── CharacterBody2D.gd # Enemy behavior
│   ├── Level/
│   │   ├── world.gd           # Level 1 logic + reward shaping
│   │   └── Level 1/
│   │       └── training.tscn  # Training scene (6 parallel instances)
│   └── addons/
│       └── godot_rl_agents/   # RL plugin
├── stable_baselines3_example.py  # Training script
└── README.md
```

## Setup

### Prerequisites
- Godot 4.5 (.NET version)
- .NET SDK 8.0
- Python 3.12+

### Installation

```bash
# Clone the repo
git clone <repo-url>
cd 360_No_Scope_rl2

# Install Python dependencies
pip install uv
uv init
uv add godot-rl

# Install .NET ONNX runtime (in Godot project folder)
cd 360_No_Scope_rl2
dotnet add package Microsoft.ML.OnnxRuntime --version 1.21.0
```

### Training

```bash
# Start training (run this, then play training.tscn in Godot)
uv run stable_baselines3_example.py --save_model_path=model.zip --timesteps=500000

# Export to ONNX for in-game use
uv run python -c "
from stable_baselines3 import PPO
from godot_rl.wrappers.onnx.stable_baselines_export import export_model_as_onnx
model = PPO.load('model.zip')
export_model_as_onnx(model, '360_No_Scope_rl2/model.onnx')
"

# Fix ONNX input name for Godot compatibility
uv run python -c "
import onnx
m = onnx.load('360_No_Scope_rl2/model.onnx')
for inp in m.graph.input:
    if inp.name == 'state_outs_orig':
        inp.name = 'state_ins'
for node in m.graph.node:
    for i in range(len(node.input)):
        if node.input[i] == 'state_outs_orig':
            node.input[i] = 'state_ins'
onnx.save(m, '360_No_Scope_rl2/model.onnx')
"
```

### Testing the Trained Model

1. Add a **Sync** node to the level scene in Godot
2. Set Sync node: **Control Mode** → ONNX Inference, **ONNX Path** → `model.onnx`
3. Set AI node: **Control Mode** → Inherit from Sync
4. Play the scene

## Key Lessons Learned

1. **Reward design is 90% of RL** — the agent always finds the easiest path to maximize reward, even if it's not what you intended
2. **Don't punish failure harshly** — reducing death penalty from -1.0 to -0.1 unlocked exploration
3. **Entropy management prevents convergence traps** — tuning `ent_coef` from 0.0001 to 0.005 kept the agent exploring
4. **Environment design matters** — making the enemy platform physically unreachable forced the intended cliff-jump strategy
5. **Debug your reward pipeline** — print statements in reward functions saved hours of blind training

## License

MIT