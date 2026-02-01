%
% Author: Abhirath Koushik
%
% Brief: Attraction/Repulsion Simulation of Elephant with Poachers,
%        Elephant (Blue circle), Green Zone (attraction), Red Zone
%        (repulsion), Poachers (Magenta moving circles)  
% 
% Revision 1 (11-15-2025): Initial simulation with 1 elephant, 2 Zones and 2 poachers
% Revision 2 (01-22-2026): Large Scale Simulation, added Mic with detection
% states, 5 red zones, 5 elephants, 2 poachers
%

clear;
clc;
close all;

% --- Screen Settings ---
WIDTH = 1000;  
HEIGHT = 700; 

% --- Simulation Scale and Speeds ---
METERS_PER_PIXEL = 20; % Considering 1px = 20m in this simulation
SPEED_ELEPHANT_MPS = 1.67; 
SPEED_POACHER_MPS = 1.11;  

% --- SETUP ZONES---
% Repulsors (Red Zones)
repulsors = struct('x', {}, 'y', {}, 'radius', {}, 'name', {});
repulsors(1) = struct('x', 380, 'y', 180, 'radius', 40, 'name', 'Nola'); 
repulsors(2) = struct('x', 410, 'y', 320, 'radius', 30, 'name', 'Salo');
repulsors(3) = struct('x', 490, 'y', 450, 'radius', 40, 'name', 'Bayanga');
repulsors(4) = struct('x', 440, 'y', 520, 'radius', 30, 'name', 'Lidjombo');
repulsors(5) = struct('x', 310, 'y', 110,  'radius', 30, 'name', 'Mossipa');

% Attractor (Green Zone)
attractor.x = 540; 
attractor.y = 400;
attractor.radius = 20; 
attractor.sensing_range = 50; 

% --- SETUP AGENTS ---
% Elephants and Behavior Details
num_elephants = 5; 
start_pos = [
    300, 200;  % North West
    500, 600;  % South
    550, 250;  % East 
    500, 400;  % West
    500, 150   % North
];
for k = 1:num_elephants
    players(k).x = start_pos(k, 1);
    players(k).y = start_pos(k, 2);
    players(k).radius = 8; 
    players(k).force_strength = 1.5; % Magnitude of attraction vector for the elephants
    players(k).wander_strength = 3.0; 
    players(k).attractorEntryTime = 0;
    players(k).state = "ROAMING"; 
    players(k).is_poached = false; 
end

% Poachers and Behavior Details
% Poacher 1: Around Bayanga
poacher1.radius = 8;
poacher1.x = repulsors(3).x + 50; poacher1.y = repulsors(3).y;
poacher1.patrol_center = [repulsors(3).x, repulsors(3).y];
poacher1.jitter=3.0; poacher1.orbit=1.0; poacher1.patrol_rad=60;

% Poacher 2: Around Nola
poacher2.radius = 8;
poacher2.x = repulsors(1).x - 50; poacher2.y = repulsors(1).y;
poacher2.patrol_center = [repulsors(1).x, repulsors(1).y];
poacher2.jitter=3.0; poacher2.orbit=1.0; poacher2.patrol_rad=60;

% --- Microphone Sensor Network ---
num_mics = 10;
mics = repmat(struct('x',0,'y',0,'active_e',false,'active_p',false,'threat',false), num_mics, 1);
mic_coords = [
    500, 200; 600, 200; 500, 350; 600, 350; 700, 350; 
    500, 500; 600, 500; 700, 250; 400, 300; 280, 250
];
for m = 1:num_mics, mics(m).x = mic_coords(m,1); mics(m).y = mic_coords(m,2); end

% --- Microphone Details ---
mic_specs.range_e = 200; % Range to detect elephants
mic_specs.range_p = 60;  % Range to detect poachers
mic_specs.threat_dist_px = 80; % Threadhold to classify as Threat

% --- GRAPHICS ---
h_fig = figure('Name', 'Dzanga Local Roaming Sim', 'Position', [50, 50, WIDTH+50, HEIGHT+50]);
set(h_fig, 'MenuBar', 'none', 'ToolBar', 'none');
ax = axes('Units', 'pixels', 'Position', [0, 0, WIDTH, HEIGHT]);
hold(ax, 'on'); axis(ax, [0 WIDTH 0 HEIGHT]); set(ax, 'YDir', 'reverse');

% Load the Map Image
try
    img = imread('Dzanga_Complete_Updated_Image.jpg'); 
    image(ax, 'XData', [0 WIDTH], 'YData', [0 HEIGHT], 'CData', img);
catch
    set(ax, 'Color', [0.1 0.2 0.1]); 
end

% Draw the Red and Green Zones
for r = 1:length(repulsors)
    rectangle(ax, 'Position', [repulsors(r).x-repulsors(r).radius, repulsors(r).y-repulsors(r).radius, repulsors(r).radius*2, repulsors(r).radius*2], ...
              'Curvature', [1 1], 'FaceColor', [1 0 0 0.3], 'EdgeColor', 'none');
    text(ax, repulsors(r).x, repulsors(r).y, repulsors(r).name, 'Color', 'w', 'FontSize', 8, 'HorizontalAlignment', 'center');
end
rectangle(ax, 'Position', [attractor.x-attractor.radius, attractor.y-attractor.radius, attractor.radius*2, attractor.radius*2], ...
          'Curvature', [1 1], 'FaceColor', [0 1 0 0.2], 'EdgeColor', 'g', 'LineWidth', 2);
rectangle(ax, 'Position', [attractor.x-attractor.sensing_range, attractor.y-attractor.sensing_range, attractor.sensing_range*2, attractor.sensing_range*2], ...
          'Curvature', [1 1], 'EdgeColor', [0 1 0 0.1], 'LineStyle', '--');


% Pre-allocate Dynamic Graphic Handles for Performance
for k=1:num_elephants, h_players(k)=plot(NaN,NaN); end
h_p1=plot(NaN,NaN); h_p2=plot(NaN,NaN);
for m=1:num_mics
    h_mics(m) = rectangle(ax, 'Position', [0 0 1 1], 'FaceColor', 'c', 'EdgeColor', 'w');
    h_rings_e(m) = rectangle(ax, 'Position', [0 0 1 1], 'Curvature', [1 1], 'EdgeColor', [0 1 1 0.1], 'LineStyle', ':');
    h_rings_p(m) = rectangle(ax, 'Position', [0 0 1 1], 'Curvature', [1 1], 'EdgeColor', [1 0 0 0.1], 'LineStyle', '-.');
end

h_threat_lines = plot(NaN, NaN, 'r-.', 'LineWidth', 2); % Red Dotted Line is drawn connecting elephant and poacher during threat
h_caught_text = text(WIDTH/2, HEIGHT/2, '', 'Color', 'r', 'FontSize', 40, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');

% --- MAIN SIMULATION LOOP ---
tic; last_time = toc;
while ishandle(h_fig)
    % Step Calculation
    dt = toc - last_time; last_time = toc;

    % Convert Real-World Speeds (m/s) to Pixel Steps
    step_e = (SPEED_ELEPHANT_MPS * 1000 * dt) / METERS_PER_PIXEL;
    step_p = (SPEED_POACHER_MPS * 1000 * dt) / METERS_PER_PIXEL;
    
    % --- Poacher Patrol Movement---
    d = norm([poacher1.x-poacher1.patrol_center(1), poacher1.y-poacher1.patrol_center(2)]);
    dx=(rand-0.5)*3; dy=(rand-0.5)*3;
    if d>0
        vec=[poacher1.x-poacher1.patrol_center(1), poacher1.y-poacher1.patrol_center(2)]/d;
        tan_v=[-vec(2), vec(1)];
        dx = dx + vec(1)*(poacher1.patrol_rad-d)*0.5 + tan_v(1)*poacher1.orbit;
        dy = dy + vec(2)*(poacher1.patrol_rad-d)*0.5 + tan_v(2)*poacher1.orbit;
    end
    mag=norm([dx,dy]); if mag>0, poacher1.x=poacher1.x+(dx/mag)*step_p; poacher1.y=poacher1.y+(dy/mag)*step_p; end
    
    % Same movement for Poacher-2
    d = norm([poacher2.x-poacher2.patrol_center(1), poacher2.y-poacher2.patrol_center(2)]);
    dx=(rand-0.5)*3; dy=(rand-0.5)*3;
    if d>0
        vec=[poacher2.x-poacher2.patrol_center(1), poacher2.y-poacher2.patrol_center(2)]/d;
        tan_v=[-vec(2), vec(1)];
        dx = dx + vec(1)*(poacher2.patrol_rad-d)*0.5 + tan_v(1)*poacher2.orbit;
        dy = dy + vec(2)*(poacher2.patrol_rad-d)*0.5 + tan_v(2)*poacher2.orbit;
    end
    mag=norm([dx,dy]); if mag>0, poacher2.x=poacher2.x+(dx/mag)*step_p; poacher2.y=poacher2.y+(dy/mag)*step_p; end
    
    % --- Elephant Movement Logic ---
    for k=1:num_elephants
        if players(k).is_poached, continue; end % Stop moving if poached
        
        dx=(rand-0.5)*players(k).wander_strength; 
        dy=(rand-0.5)*players(k).wander_strength;
        d_attr = norm([players(k).x-attractor.x, players(k).y-attractor.y]);
        
        % State Machine Transitions
        if players(k).state == "ROAMING"
            if d_attr < attractor.sensing_range, players(k).state = "SEEKING"; end
        elseif players(k).state == "SEEKING"
            if d_attr < attractor.radius
                players(k).state = "WAITING"; players(k).attractorEntryTime = toc;
            elseif d_attr > attractor.sensing_range + 50
                players(k).state = "ROAMING";
            else
                dx = dx + ((attractor.x-players(k).x)/d_attr)*players(k).force_strength;
                dy = dy + ((attractor.y-players(k).y)/d_attr)*players(k).force_strength;
            end
        elseif players(k).state == "WAITING"
            if toc - players(k).attractorEntryTime > 8, players(k).state = "ROAMING"; end
        end
        
        % Repulsion from Red Zones
        for r=1:length(repulsors)
            d_rep = norm([players(k).x-repulsors(r).x, players(k).y-repulsors(r).y]);
            if d_rep < repulsors(r).radius + 30
                 dx = dx + ((players(k).x-repulsors(r).x)/d_rep)*8.0; 
                 dy = dy + ((players(k).y-repulsors(r).y)/d_rep)*8.0;
            end
        end

        % Update Position
        mag=norm([dx,dy]); if mag>0, players(k).x=players(k).x+(dx/mag)*step_e; players(k).y=players(k).y+(dy/mag)*step_e; end
        players(k).x=max(10,min(WIDTH-10,players(k).x)); players(k).y=max(10,min(HEIGHT-10,players(k).y));
    end
    
    % --- Mic Sensor Network Logic ---
    network_threat_active = false;
    threat_lines_x = []; threat_lines_y = [];
    
    for m = 1:num_mics
        mics(m).active_e = false; mics(m).active_p = false; mics(m).threat = false;
        
        % Detect Elephants (Rumbles Range)
        for k=1:num_elephants
            if norm([players(k).x-mics(m).x, players(k).y-mics(m).y]) < mic_specs.range_e, mics(m).active_e = true; end
        end

        % Detect Poachers
        if norm([poacher1.x-mics(m).x, poacher1.y-mics(m).y]) < mic_specs.range_p, mics(m).active_p = true; end
        if norm([poacher2.x-mics(m).x, poacher2.y-mics(m).y]) < mic_specs.range_p, mics(m).active_p = true; end
        
        % Threat Logic - If mic detects both Elephant and Poacher
        if mics(m).active_e && mics(m).active_p
            for k=1:num_elephants
                d_p1 = norm([players(k).x-poacher1.x, players(k).y-poacher1.y]);
                d_p2 = norm([players(k).x-poacher2.x, players(k).y-poacher2.y]);

                % If poacher within thread_dist then trigger Alert
                if d_p1 < mic_specs.threat_dist_px || d_p2 < mic_specs.threat_dist_px
                    mics(m).threat = true; network_threat_active = true;

                    % Visualize the threat vector bn elephant and poacher
                    if d_p1 < mic_specs.threat_dist_px
                        threat_lines_x = [threat_lines_x, players(k).x, poacher1.x, NaN];
                        threat_lines_y = [threat_lines_y, players(k).y, poacher1.y, NaN];
                    else
                        threat_lines_x = [threat_lines_x, players(k).x, poacher2.x, NaN];
                        threat_lines_y = [threat_lines_y, players(k).y, poacher2.y, NaN];
                    end
                end
            end
        end
    end
    
    % --- Poaching Check Logic ---
    any_caught = false;
    for k = 1:num_elephants
        if players(k).is_poached, any_caught = true; continue; end
        
        if norm([players(k).x-poacher1.x, players(k).y-poacher1.y]) < 20 || ...
           norm([players(k).x-poacher2.x, players(k).y-poacher2.y]) < 20
            players(k).is_poached = true;
            any_caught = true;
        end
    end
    
    % --- FRAME UPDATES ---
    
    % Update Poachers
    set(h_p1, 'XData', poacher1.x, 'YData', poacher1.y, 'Marker', 'o', 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'w');
    set(h_p2, 'XData', poacher2.x, 'YData', poacher2.y, 'Marker', 'o', 'MarkerFaceColor', 'm', 'MarkerEdgeColor', 'w');
    
    % Update Elephants
    for k=1:num_elephants
        if players(k).is_poached
             set(h_players(k), 'XData', players(k).x, 'YData', players(k).y, 'Marker', 'x', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'MarkerSize', 12, 'LineWidth', 2);
        else
             set(h_players(k), 'XData', players(k).x, 'YData', players(k).y, 'Marker', 'o', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'w', 'MarkerSize', 10);
        end
    end

    % Update Sensors
    for m=1:num_mics
        color = 'c'; if mics(m).active_e, color = 'b'; end; if mics(m).active_p, color = 'r'; end; if mics(m).threat, color = [1 0 0]; end
        set(h_mics(m), 'Position', [mics(m).x-5, mics(m).y-5, 10, 10], 'FaceColor', color);
        set(h_rings_e(m), 'Position', [mics(m).x-mic_specs.range_e, mics(m).y-mic_specs.range_e, mic_specs.range_e*2, mic_specs.range_e*2]);
        set(h_rings_p(m), 'Position', [mics(m).x-mic_specs.range_p, mics(m).y-mic_specs.range_p, mic_specs.range_p*2, mic_specs.range_p*2]);
    end
    
    % Draw Threat Vectors
    set(h_threat_lines, 'XData', threat_lines_x, 'YData', threat_lines_y);
    
    % Draw Poached String on screen 
    if any_caught
        set(h_caught_text, 'String', 'POACHED!');
    else
        set(h_caught_text, 'String', '');
    end
    
    drawnow limitrate;
end
