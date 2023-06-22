import numpy as np
import pandas as pd
import slippi
from slippi import Game
import os
import sys
import gc 
import feather

all_frames = pd.DataFrame(columns = [ 'stage',
        'p1_character',
        'p1_state',
        'p1_position_x',
        'p1_position_y',
        'p1_direction',
        'p1_damage',
        'p1_shield',
        'p1_stocks',
        'p1_last_landed',
        'p1_last_hit_by',
        'p1_combo_count',
        'p1_joystick_x',
        'p1_joystick_y',
        'p1_cstick_x',
        'p1_cstick_y',
        'p1_triggers',
        'p1_buttons',
        'p1_seed',
        'p2_character',
        'p2_state',
        'p2_position_x',
        'p2_position_y',
        'p2_direction',
        'p2_damage',
        'p2_shield',
        'p2_stocks',
        'p2_last_landed',
        'p2_last_hit_by',
        'p2_combo_count',
        'p2_joystick_x',
        'p2_joystick_y',
        'p2_cstick_x',
        'p2_cstick_y',
        'p2_triggers',
        'p2_buttons',
        'p2_seed'])

def add_frame(frame,p1,p2,stage):
    global all_frames
    
    frame_data = {
        'stage': stage,
        'p1_character':  frame.ports[p1].leader.post.character,
        'p1_state': frame.ports[p1].leader.post.state,
        'p1_position_x': frame.ports[p1].leader.post.position.x,
        'p1_position_y': frame.ports[p1].leader.post.position.y,
        'p1_direction': frame.ports[p1].leader.post.direction,
        'p1_damage': frame.ports[p1].leader.post.damage,
        'p1_shield': frame.ports[p1].leader.post.shield,
        'p1_stocks': frame.ports[p1].leader.post.stocks,
        'p1_last_landed': frame.ports[p1].leader.post.last_attack_landed,
        'p1_last_hit_by': frame.ports[p1].leader.post.last_hit_by,
        'p1_combo_count': frame.ports[p1].leader.post.combo_count,
        'p1_joystick_x': frame.ports[p1].leader.pre.joystick.x,
        'p1_joystick_y': frame.ports[p1].leader.pre.joystick.y,
        'p1_cstick_x': frame.ports[p1].leader.pre.cstick.x,
        'p1_cstick_y': frame.ports[p1].leader.pre.cstick.y,
        'p1_triggers': frame.ports[p1].leader.pre.triggers.logical,
        'p1_buttons': frame.ports[p1].leader.pre.buttons.logical,
        'p1_seed': frame.ports[p1].leader.pre.random_seed,
        'p2_character':  frame.ports[p2].leader.post.character,
        'p2_state': frame.ports[p2].leader.post.state,
        'p2_position_x': frame.ports[p2].leader.post.position.x,
        'p2_position_y': frame.ports[p2].leader.post.position.y,
        'p2_direction': frame.ports[p2].leader.post.direction,
        'p2_damage': frame.ports[p2].leader.post.damage,
        'p2_shield': frame.ports[p2].leader.post.shield,
        'p2_stocks': frame.ports[p2].leader.post.stocks,
        'p2_last_landed': frame.ports[p2].leader.post.last_attack_landed,
        'p2_last_hit_by': frame.ports[p2].leader.post.last_hit_by,
        'p2_combo_count': frame.ports[p2].leader.post.combo_count,
        'p2_joystick_x': frame.ports[p2].leader.pre.joystick.x,
        'p2_joystick_y': frame.ports[p2].leader.pre.joystick.y,
        'p2_cstick_x': frame.ports[p2].leader.pre.cstick.x,
        'p2_cstick_y': frame.ports[p2].leader.pre.cstick.y,
        'p2_triggers': frame.ports[p2].leader.pre.triggers.logical,
        'p2_buttons': frame.ports[p2].leader.pre.buttons.logical,
        'p2_seed': frame.ports[p2].leader.pre.random_seed
        }
    all_frames = all_frames.append(frame_data, ignore_index = True)
   


def validate_game(fname):
    try:
        game = Game('games/' + fname)
        return game
    except KeyboardInterrupt:
        sys.exit()
    except:
        print('Game ' + fname + ' contains corrupt data.')
        return None

def main():
   game_num = 1
   for fname in os.listdir('games/'):
       game = validate_game(fname)
       #Get the ports
       frame_one = game.frames[1]
       stage = game.start.stage
       ports = frame_one.ports
       players = list()
       for port_num in range(4):
            if ports[port_num]:
                players.append(port_num)
       for frame in game.frames:
            add_frame(frame,players[0],players[1],stage)
       path = 'game' + str(game_num)+'.feather'
       feather.write_dataframe(all_frames, path) 
       game_num = game_num + 1
   
   print("done")
if __name__ == "__main__":
    main()
