# 18-224/624 S25 Tapeout Doc Files
This folder contains all docs related to the design process. 
## Original Proposal: original_proposal.txt  
Description: The first version of tetris I proposed as my main idea. My backup was MS paint.

## Design Proposal 1: design_proposal_1.pdf  
Description: More fleshed out grid and piece logic. 
Major changes since the original proposal:
- Tetris grid architecture became more similar to an SRAM
- Removed audio from design due to complexity of the rest of the project

## Design Proposal 2: design_proposal_2.pdf  
Description: Preliminary game FSM and datapath.
Major changes since design proposal 1:
- Modified piece logic to only keep track of the top left corner with combinational logic to extract each pixel's location

## Design Proposal 3: design_proposal_2.pdf  
Description: the full FSM and datapath for the entire desgn.