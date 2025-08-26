# Card Dealing System

This is a new simplified card table scene (`card_table_gb.tscn`) that demonstrates realistic card dealing physics from scratch.

## Features

### Scene Structure
- **Graybox Table**: Simple CSGBox3D table with a dark gray material
- **Card Deck**: Visual representation of a card deck at the bottom of the screen
- **Card Positions**: 4 rows of 5 cards each, positioned on the table
- **Camera**: Positioned above the table for a good view of the dealing action

### Dealing Physics
- **Natural Arc Trajectory**: Cards follow realistic ballistic paths from deck to table
- **Controlled Flight**: Cards maintain stable trajectories with minimal randomness
- **Realistic Sliding**: Cards slide naturally on the table surface when landing
- **Smooth Flipping**: Cards flip from face-down to face-up with natural animations

### Card Properties
- **Random Values**: Each card gets a random value (1-10)
- **Random Icons**: Cards display random icons (attack, shield, gold, pillage, special_item)
- **Physics-Based**: Cards use RigidBody3D with realistic physics materials

## How to Use

1. **Open the Scene**: Load `card_table_gb.tscn` in Godot
2. **Deal Cards**: Click the "Deal Cards" button to start dealing
3. **Watch the Action**: Cards will fly from the deck to their positions on the table
4. **Reset**: Click "Reset" to clear all cards and deal again

## Technical Details

### Physics Settings
- **Launch Force**: 8.0 (controls how fast cards travel)
- **Arc Height**: 1.5 (controls the height of the flight arc)
- **Slide Friction**: 0.92 (controls how much cards slide)
- **Slide Threshold**: 0.05 (when sliding stops)

### Card Behavior
- Cards start face-down (rotated 180° on Z-axis)
- During flight, cards have slight random rotation for realism
- Landing triggers sliding with controlled friction
- After sliding stops, cards flip to reveal their faces
- Flip animation includes a small bounce and rotation

### Scene Hierarchy
```
CardTableGB (Node3D)
├── Table (CSGBox3D)
├── CardDeck (Node3D + CardDealer script)
│   ├── DeckModel (CSGBox3D)
│   ├── DeckModel2 (CSGBox3D)
│   ├── DeckModel3 (CSGBox3D)
│   ├── DeckModel4 (CSGBox3D)
│   └── DeckModel5 (CSGBox3D)
├── CardPositions (Node3D)
│   ├── Row1 (Node3D)
│   │   ├── Pos1 (Marker3D)
│   │   ├── Pos2 (Marker3D)
│   │   ├── Pos3 (Marker3D)
│   │   ├── Pos4 (Marker3D)
│   │   └── Pos5 (Marker3D)
│   ├── Row2 (Node3D)
│   ├── Row3 (Node3D)
│   └── Row4 (Node3D)
├── Camera3D
├── DirectionalLight3D
└── CanvasLayer
    ├── DealButton
    └── ResetButton
```

## Customization

### Adjusting Physics
Modify the export variables in `CardDealer.gd`:
- `deal_speed`: Time between card deals
- `launch_force`: How fast cards travel
- `arc_height`: Height of the flight arc
- `slide_friction`: How much cards slide
- `slide_threshold`: When sliding stops

### Adding More Cards
To add more card positions:
1. Add new rows under `CardPositions`
2. Add position markers under each row
3. The system automatically detects new positions

### Changing Card Appearance
Modify `Card3D.tscn` to change:
- Card size and shape
- Material properties
- Label positioning and styling
- Icon sprite properties

## Performance Notes

- Cards use efficient CSGBox3D for the model
- Physics are optimized with appropriate collision layers
- Cards are automatically cleaned up when resetting
- The system handles up to 20 cards efficiently

## Troubleshooting

### Cards Not Moving
- Check that the Card3D script is properly attached
- Verify collision layers are set correctly
- Ensure the card deck has the CardDealer script

### Cards Flying Off Screen
- Reduce `launch_force` in CardDealer
- Check that target positions are within reasonable bounds
- Verify spawn and target positions are set correctly

### Cards Not Sliding
- Check physics material properties
- Verify `slide_friction` and `slide_threshold` values
- Ensure cards are landing on the table surface
