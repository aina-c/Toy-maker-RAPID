MODULE Module1
    !Define tooldata
    PERS tooldata VacuumTool:=[TRUE,[[106.338,-0.37,126.015],[0.92388,0,0.382683,0]],[1,[0,0,1],[1,0,0,0],0,0,0]];
    PERS tooldata PenTool:=[TRUE,[[-174.289,-0.18,194.277],[0.92388,0,-0.382683,0]],[1,[0,0,1],[1,0,0,0],0,0,0]];
    
    !Define workobjects
    PERS wobjdata Table_ready:=[FALSE,TRUE,"",[[-869.193,-200,500],[0,0,1,0]],[[0,0,0],[1,0,0,0]]];
    PERS wobjdata Table_draw:=[FALSE,TRUE,"",[[-410.567,700,500],[0,0.707107,0.707107,0]],[[0,0,0],[1,0,0,0]]];
    
    !Two robtargets defined by guidance, one for each workobject
    CONST robtarget Target_30:=[[350,200,-350],[0,0,0,1],[0,-1,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]];
    CONST robtarget Target_40:=[[350,350,-350],[0,0,0,1],[-1,-1,0,0],[9E+09,9E+09,9E+09,9E+09,9E+09,9E+09]]; 

    !Constants for offsets and velocities
    CONST num offset:=50;
    CONST speeddata velocity_free := v1000; !Moves between tables
    CONST speeddata velocity_near := v500; !Moves near objects
    CONST speeddata velocity_approaching := v100; !Approach objects
    CONST speeddata velocity_paint:= v60; !Velocity when painting
    
    !Variable for TRAP
    VAR intnum  stopDI ;
    
    PROC main()
        !Defining mood and the face center to send later to Draw_face
        VAR num mood;   
        VAR robtarget face_starter;
        
        !Connecting signals of TRAP
        CONNECT stopDI WITH stop_robot;
        ISignalDI DI_interrupt,1, stopDI;
        
        !Setting all signals to 0
        SetDO vacuum2,0;
        SetDO finished,0;
        SetDO paint,0;
        
        WaitTime 3;!To avoid signal errors
        
        !Wait for the toy to be assembled
        WaitDI ready,1; 
        
        !Print a message in the FlexPendant 
        TPWrite "Toy is assembled and ready to paint";
        
        !Pick toy and place it in the table to paint
        Get_toy;
        
        !Ask for a happy or sad face
        TPReadNum mood, "Enter 0 for a happy face or 1 for a sad face";
        
        !Defining first eye point with the right orientation
        face_starter := Offs(Target_40,-50,-25,30);
        face_starter.rot:=[0.707107,0,0.707107,0];
        
        !Draw face according to the mood
        Draw_face face_starter, mood;
        
        !Send signal to show that Toy is finished
        SetDO finished,1;
        
        !Move to a safe position
        MoveJ Offs(Target_40,-500,-300,-150), velocity_near,z10,tool0\WObj:=Table_draw;
        
        WaitTime 10;
        
    ENDPROC
    
    PROC Get_toy()
        !It approaches the object in the z direction with the vacuum tool
        MoveJ Offs(Target_30,0,0,-offset),velocity_free,z10,VacuumTool\WObj:=Table_ready;
        MoveL Offs(Target_30,0,0,-7),velocity_approaching,fine,VacuumTool\WObj:=Table_ready;
        
        !Activate vacuum tool
        SetDO vacuum2,1;
        WaitTime 1;!Picking object
        
        !Move away
        MoveL Offs(Target_30,0,0,-offset),velocity_approaching,fine,VacuumTool\WObj:=Table_ready;
        
        !Move to the approaching point, with an offset in z direction from target
        MoveJ Offs(Target_40,0,0,-offset),velocity_free,fine,VacuumTool\WObj:=Table_draw; 
        MoveL Offs(Target_40,0,0,-7),velocity_approaching,fine,VacuumTool\WObj:=Table_draw;
        
        !Deactivate vacuum tool
        SetDO vacuum2,0;
        WaitTime 1;!Detach object
        
    ENDPROC
   
    PROC Draw_face(robtarget Objective, num mood)
        !Define middle_point to perform MoveC
        VAR robtarget middle_point;
        
        !Paint first eye
        MoveJ Offs(Objective,-offset,0,0), velocity_free,z10,PenTool\WObj:=Table_draw;
        MoveL Objective, velocity_approaching,fine,PenTool\WObj:=Table_draw;
        !Set paint to 1, to activate the path color
        SetDO paint,1;
        MoveL Offs(Objective,0,5,0), velocity_paint,fine,PenTool\WObj:=Table_draw;
        SetDO paint,0;
        !Move away
        MoveL Offs(Objective,-offset,5,0), velocity_free,z10,PenTool\WObj:=Table_draw;
        
        !Paint right eye
        Objective.trans.y:= Objective.trans.y + 50;
        MoveJ Offs(Objective,-offset,-5,0), velocity_near,z10,PenTool\WObj:=Table_draw;
        MoveL Offs(Objective,0,-5,0),velocity_approaching,fine,PenTool\WObj:=Table_draw;
        !Set paint to 1, to activate the path color
        SetDO paint,1;
        MoveL Objective, velocity_paint,fine,PenTool\WObj:=Table_draw;
        SetDO paint,0;
        !Move away
        MoveL Offs(Objective,-offset,5,0), velocity_free,z10,PenTool\WObj:=Table_draw;
        
        !Store the start of the mouth point
        Objective.trans.z:= Objective.trans.z +25;
        MoveJ Offs(Objective,-offset,0,0), velocity_near,z10,PenTool\WObj:=Table_draw;
        MoveL Objective, velocity_approaching,fine,PenTool\WObj:=Table_draw;
        
        TEST mood
            CASE 0:
                !Happy
                middle_point:=Offs(Objective,0,-25,20);
                Objective.trans.y:= Objective.trans.y - 50;
                SetDO paint,1;
                MoveC middle_point, Objective, velocity_paint,fine,PenTool\WObj:=Table_draw;
            CASE 1:
                !Sad
                middle_point:=Offs(Objective,0,-25,-20);
                Objective.trans.y:= Objective.trans.y - 50;
                SetDO paint,1;
                MoveC middle_point, Objective, velocity_paint,fine,PenTool\WObj:=Table_draw;
            DEFAULT:
                !Normal
                Objective.trans.y:= Objective.trans.y - 50;
                SetDO paint,1;
                MoveL Objective, velocity_paint,fine,PenTool\WObj:=Table_draw;
        ENDTEST
        SetDO paint,0;
        MoveL Offs(Objective,-offset,0,0), velocity_approaching,z10,PenTool\WObj:=Table_draw;
        
    ENDPROC
    
    TRAP stop_robot
        StopMove;
        WaitDI DI_interrupt, 0;
        StartMove;
    ENDTRAP            
                                                             
ENDMODULE
