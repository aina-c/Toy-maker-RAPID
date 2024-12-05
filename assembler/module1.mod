MODULE Module1
    !Define workobjects
    PERS wobjdata Table_parts:=[FALSE,TRUE,"",[[-350,700,500],[0,0.707107,0.707107,0]],[[0,0,0],[1,0,0,0]]];
    PERS wobjdata Table_assembly:=[FALSE,TRUE,"",[[700,200,500],[0,1,0,0]],[[0,0,0],[1,0,0,0]]];
    
    !Define tooldata
    PERS tooldata VacuumTool:=[TRUE,[[106.338,-0.37,126.015],[0.92388,0,0.382683,0]],[1,[0,0,1],[1,0,0,0],0,0,0]];
    PERS tooldata PenTool:=[TRUE,[[-174.289,-0.18,194.277],[0.92388,0,-0.382683,0]],[1,[0,0,1],[1,0,0,0],0,0,0]];

    !Two robtargets defined by guidance, one for each workobject
    CONST robtarget Target_10:=[[350,200,-250],[0.707106781,0,0,0.707106781],[0,-1,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_20:=[[150,150,0],[0,0.707106781,0,0.707106781],[1,0,-2,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    
    !Variables that define the parts of the toy
    VAR num width_b := 200; !Width of body
    VAR num depth_b := 150; !depth of body
    VAR num height_b := 250; !height of body
    VAR num edge_h := 100; !edge of the head -- It's a cube
    VAR num width_a := 50; !width of arm -- Base of arm is a square
    VAR num height_a := 200; !Height of arm
    
    !Target that will be change with offsets 
    VAR robtarget Objective;

    !Constants for offsets and velocities
    CONST num offset:=100;
    CONST speeddata velocity_free := v1000; !Moves between tables
    CONST speeddata velocity_near := v800; !Moves near objects
    CONST speeddata velocity_approaching := v100; !Approach objects
    
    !Variable for TRAP
    VAR intnum  stopDI ;
     
    
    PROC main()
        !Connecting signals of TRAP
        CONNECT stopDI WITH stop_robot;
        ISignalDI DI_interrupt,1, stopDI;
        
        !Setting all signals to 0
        SetDO vacuum,0;
        SetDO finished,0;
        SetDO screw,0;
        SetDO blue_assemble,0;
        SetDO red_assemble,0;

        !Pick and place body
        Path_body;
        
        !Pick and place head
        Path_head; 
        
        !Pick and place arms
        Path_arm;
        
        !"Screw" everything
        Screw_head_arms;
        
        !Move to a save position
        ConfJ\On;
        ConfL\On;
        MoveJ Offs(Target_20,0,0,-300),velocity_free,z10,PenTool\WObj:=Table_parts;
        
        !Send signal to start painter robot
        SetDO finished,1;
        !Print a message in the FlexPendant 
        TPWrite "Robot is assembled and ready to paint";
        
    ENDPROC
    
    
    PROC Path_body()
        
        Pick_body(position("body","start")); 
        Place_object(position("body","end")); 
        
    ENDPROC
    
    PROC Path_head()
        
        Pick_object(position("head","start"));
        Place_object(position("head","end"));
        
    ENDPROC
    
    PROC Path_arm()
        !Variable to adjust offset depending on the arm
        VAR num dir :=1;
        
        !check condition signaled by user
        IF DInput(arm_color) = 0 THEN
            !Blue arms
            Pick_object(position("arm_b1","start"));
            Place_arm position("arm_b1","end"),-dir;
            
            Pick_object(position("arm_b2","start"));
            Place_arm position("arm_b2","end"), dir;
            
            !Send signal to SmartComponent
            SetDO blue_assemble,1;
        ELSE
            !Red arms
            Pick_object(position("arm_r1","start"));
            Place_arm position("arm_r1","end"),-dir;
            
            Pick_object(position("arm_r2","start"));
            Place_arm position("arm_r2","end"), dir;
            
            !Send signal to SmartComponent
            SetDO red_assemble,1;
        ENDIF
        
    ENDPROC
    
    PROC Pick_body(robtarget point) 
        !It approaches the object in the x direction with the vacuum tool
        MoveJ Offs(point,-offset,0,0),velocity_free,z10,VacuumTool\WObj:=Table_parts; 
        MoveL Offs(point,-7,0,0),velocity_approaching,fine,VacuumTool\WObj:=Table_parts;
        
        !Activate vacuum tool
        SetDO vacuum,1;
        WaitTime 1; !Picking object
        
        !Move up to avoid other objects
        MoveL Offs(point,0,0,-300),velocity_approaching,fine,VacuumTool\WObj:=Table_parts;
        
        
        ConfJ\Off; !This avoids weird movements
        ConfL\Off;
        
    ENDPROC
    
    PROC Pick_object(robtarget point) 
        !It approaches the object in the z direction with the vacuum tool
        MoveJ Offs(point,0,0,-offset),velocity_free,z10,VacuumTool\WObj:=Table_parts;
        MoveL Offs(point,0,0,-7),velocity_approaching,fine,VacuumTool\WObj:=Table_parts;
        
        !Activate vacuum tool
        SetDO vacuum,1;
        WaitTime 1;!Picking object
        
        !Move away
        MoveL Offs(point,0,0,-100),velocity_approaching,fine,VacuumTool\WObj:=Table_parts;
        
        ConfJ\Off;!This avoids weird movements
        ConfL\Off;
    ENDPROC
    
    PROC Place_object(robtarget point)
        ConfJ\On;!It avoids weird movements
        ConfL\On;
        
        !Move to the approaching point, with an offset in z direction from target
        MoveJ Offs(point,0,0,-offset),velocity_free,z10,VacuumTool\WObj:=Table_assembly;
        MoveL Offs(point,0,0,-7),velocity_approaching,fine,VacuumTool\WObj:=Table_assembly;
        
        !Deactivate vacuum tool
        SetDO vacuum,0;
        WaitTime 1; !Detach object
        
        !Move up again
        MoveL Offs(point,0,0,-offset),velocity_approaching,fine,VacuumTool\WObj:=Table_assembly;
        
    ENDPROC
    
    PROC Place_arm(robtarget point, num direction)
        !Moves to safe point above assembly
        MoveJ Offs(Target_10,0,0,-500),velocity_free,z10,VacuumTool\WObj:=Table_assembly;
        
        !Moves to approaching point depending on the arm -- right or left
        MoveJ Offs(point,0,direction*offset,0),velocity_near,z10,VacuumTool\WObj:=Table_assembly;
        MoveL Offs(point,0,7*direction,0),velocity_approaching,fine,VacuumTool\WObj:=Table_assembly;
        
        !Deactivate vacuum tool
        SetDO vacuum,0;
        WaitTime 1; !Detach object
        
        !Move away
        MoveL Offs(point,0,offset*direction,0),velocity_approaching,fine,VacuumTool\WObj:=Table_assembly;
 
    ENDPROC
    
    PROC Screw_head_arms()
        !Move to safe point above assembly (Which is aligned with center of the head)
        MoveJ Offs(Target_10,0,0,-500),velocity_free,z10,PenTool\WObj:=Table_assembly;
        !Move to an approaching point above head
        MoveJ Offs(Target_10,0,0,-edge_h - 50),velocity_near,z10,PenTool\WObj:=Table_assembly;
        
        !Screw head
        !Send signal to show it is screwing
        SetDO screw, 1; 
        MoveL Offs(Target_10,0,0,-edge_h + 50),velocity_approaching,fine,PenTool\WObj:=Table_assembly;!Move inside head
        WaitTime 1; !Screwing
        MoveL Offs(Target_10,0,0,-edge_h - 50),velocity_approaching,fine,PenTool\WObj:=Table_assembly;!Move to approaching point
        SetDO screw, 0;
        
        MoveJ Offs(Target_10,0,0,-500),velocity_free,z10,PenTool\WObj:=Table_assembly;
        
        !Screw arm 1
        !Define arm surface point where it screws
        Objective :=Offs(Target_10,0,-width_b/2 - 50,75);
        Objective.rot := [0.707106781,-0.707106781,0,0];! Rotation to screw horizontally
        
        MoveJ Offs(Objective,0,-50,0),velocity_near,z10,PenTool\WObj:=Table_assembly;!Move to approaching point
        SetDO screw, 1;!Send signal to show it is screwing
        MoveL Offs(Objective,0,+50,0),velocity_approaching,fine,PenTool\WObj:=Table_assembly;!Move inside arm
        WaitTime 1; !Screwing
        MoveL Offs(Objective,0,-50,0),velocity_approaching,fine,PenTool\WObj:=Table_assembly;!Move to approaching point
        SetDO screw, 0;
        
        !Move again to safe point above assembly
        MoveJ Offs(Target_10,0,0,-500),velocity_free,z10,PenTool\WObj:=Table_assembly;
        
        !Screw arm 2
        !Define arm surface point where it screws
        Objective :=Offs(Target_10,0,width_b/2 + 50,75);
        Objective.rot := [0.707106781,0.707106781,0,0];! Rotation to screw horizontally
        
        MoveJ Offs(Objective,0,+50,0),velocity_near,z10,PenTool\WObj:=Table_assembly;!Move to approaching point
        SetDO screw, 1;!Send signal to show it is screwing
        MoveL Offs(Objective,0,-50,0),velocity_approaching,fine,PenTool\WObj:=Table_assembly;!Move inside arm
        WaitTime 1;!Screwing
        MoveL Offs(Objective,0,+50,0),velocity_approaching,fine,PenTool\WObj:=Table_assembly;!Move to approaching point
        SetDO screw, 0;
        
        !Move up to avoid objects
        MoveL Offs(Objective,0,+50,-350),velocity_approaching,fine,PenTool\WObj:=Table_assembly;

    ENDPROC

    FUNC robtarget position(string part,string where)
        !This FUNC receives the name of the part, and if it wants the start position or the end position
        TEST part
            CASE "body":
                IF where = "start" THEN
                    Objective := Target_20;
                    Objective.trans.z:=Objective.trans.z - width_b/2;
                    Objective.trans.y:=Objective.trans.y + depth_b/2;
                    RETURN Objective;
                ELSE
                    Objective := Target_10;
                    RETURN Objective;
                ENDIF
            
            CASE "head": 
                IF where = "start" THEN
                    Objective := Target_20;
                    Objective := Offs(Objective,400,edge_h/2,-edge_h);
                    Objective.rot := [1,0,0,0];
                    RETURN Objective;
                ELSE
                    Objective := Target_10;
                    Objective := Offs(Objective,0,0,-edge_h);
                    RETURN Objective;
                ENDIF
                
            CASE "arm_b1":   
                IF where = "start" THEN
                    Objective := Target_20;
                    Objective.rot := [1,0,0,0];
                    Objective := Offs(Objective,height_a/2,325,-width_a);
                    RETURN Objective;
                ELSE 
                    Objective:=Offs(Target_10,0,-width_b/2 - width_a,150);
                    Objective.rot := [0.5,-0.5,0.5,0.5];
                    RETURN Objective;
                ENDIF
                    
            CASE "arm_b2":   
                IF where = "start" THEN
                    Objective := Target_20;
                    Objective.rot := [1,0,0,0];
                    Objective := Offs(Objective,height_a/2,325,-width_a);
                    Objective := Offs(Objective,300,0,0);
                    RETURN Objective;
                ELSE
                    Objective:=Offs(Target_10,0,width_b/2 + width_a,150);
                    Objective.rot := [0.5,0.5,0.5,-0.5];
                    RETURN Objective;
                ENDIF
                
            CASE "arm_r1":   
                IF where = "start" THEN
                    Objective := Target_20;
                    Objective.rot := [1,0,0,0];
                    Objective := Offs(Objective,height_a/2,425,-width_a);
                    RETURN Objective;
                ELSE
                    Objective:=Offs(Target_10,0,-width_b/2 - width_a,150);
                    Objective.rot := [0.5,-0.5,0.5,0.5];
                    RETURN Objective;
                ENDIF
                
            CASE "arm_r2":   
                IF where = "start" THEN
                    Objective := Target_20;
                    Objective.rot := [1,0,0,0];
                    Objective := Offs(Objective,height_a/2,425,-width_a);
                    Objective := Offs(Objective,300,0,0);
                    RETURN Objective;
                ELSE
                    Objective:=Offs(Target_10,0,width_b/2 + width_a,150);
                    Objective.rot := [0.5,0.5,0.5,-0.5];
                    RETURN Objective;
                ENDIF
        ENDTEST
    ENDFUNC
    
    TRAP stop_robot
        StopMove;
        WaitDI DI_interrupt, 0;
        StartMove;
    ENDTRAP
ENDMODULE
