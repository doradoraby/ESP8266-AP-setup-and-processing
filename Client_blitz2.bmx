
'''''''''''''''''''''''''''''''''''''''''''''''

Strict

Import "color.bmx"




Incbin "stars.png"

Incbin "player.png"

Incbin "bullet.png"

Incbin "shoot.wav"




Const WIDTH=640,HEIGHT=480

Const DEPTH=32,HERTZ=60




Const GRAVITY#=.15,SPARKS_PER_FRAME=55




Global sparks:TList=New TList

Global bullets:TList=New TList




Type TEntity




Field link:TLink




Method remove()

  link.remove

End Method




Method AddLast( list:TList )

  link=list.AddLast( Self )

End Method




Method Update() Abstract




End Type




Type TSpark Extends TEntity




Field x#,y#,xs#,ys#

Field color[3],rot#,rots#




Method Update()




  ys:+GRAVITY

  x:+xs

  y:+ys




  If x<0 Or x>=WIDTH Or y>=HEIGHT

  remove

  Return

  EndIf




  rot=rot+rots

  SetHandle 8,8

  SetRotation rot#

  SetAlpha 1-y/HEIGHT

  SetColor color[0],color[1],color[2]

  DrawRect x,y,17,17

  SetHandle 0,0




End Method




Function CreateSpark:TSpark( x#,y#,color[] )

  Local spark:TSpark=New TSpark

  Local an#=Rnd(360),sp#=Rnd(3,5)

  spark.x=x

  spark.y=y

  spark.xs=Cos(an)*sp

  spark.ys=Sin(an)*sp

  spark.rots=Rnd(-15,15)

  spark.color=color

  spark.AddLast sparks

  Return spark

End Function




End Type




Type TBullet Extends TEntity




Field x#,y#,ys#

Field rot#,img:TImage




Method Update()

  ys:-.01

  y:+ys

  If y<0

  remove

  Return

  EndIf

  rot:+3

  SetRotation rot

  DrawImage img,x,y

End Method




Function CreateBullet:TBullet( x#,y#,img:TImage )

  Local bullet:TBullet=New TBullet

  bullet.x=x

  bullet.y=y

  bullet.ys=-1 

  bullet.img=img

  bullet.AddLast bullets

  Return bullet

End Function




End Type




Function UpdateEntities( list:TList )

For Local entity:TEntity=EachIn list

  entity.Update

Next

End Function




Graphics WIDTH,HEIGHT,DEPTH,HERTZ




AutoMidHandle True




Local fire:TSound=LoadSound( "incbin::shoot.wav" )

Local dude:TImage=LoadImage( "incbin::player.png" ),dude_x=WIDTH/2,dude_y=HEIGHT-30

Local bull:TImage=LoadImage( "incbin::bullet.png" ),bull_x,bull_y

Local stars:TImage=LoadImage( "incbin::stars.png" ),stars_x,stars_y




Local show_debug,color_rot#




'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

Local client:TSocket = CreateTCPSocket ()




HideMouse




If client

  Local ip:String = "192.168.4.1"

  Local integer_ip:Int = HostIp (ip)

  Local axis[9]




  If ConnectSocket (client, integer_ip, 23)




  Local stream:TStream = CreateSocketStream (client)

  If stream




'  Repeat

'  For Local i : Int = 1 To 9

 ' Local incoming : Float = ReadFloat(stream)

 ' axis[i-1] = incoming*100000000

 ' 'Print  Float axis[i-1]*0.00000001

 ' Next

  ''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

  While Not KeyHit( KEY_ESCAPE )




For Local i : Int = 1 To 9

Local incoming : Float = ReadFloat(stream)

axis[i-1] = incoming*100



'Print axis[i-1]



Next



Cls



stars_y:+1

SetBlend MASKBLEND

TileImage stars,stars_x,stars_y

TileImage stars,stars_x+7,stars_y*2

TileImage stars,stars_x+7,stars_y*3





'dude_x:+axis[3]



'If KeyDown( KEY_LEFT )

'dude_x:-5

'Else If  KeyDown( KEY_RIGHT )

'  dude_x:+5

'EndIf

'

'SetBlend MASKBLEND

'DrawImage dude,dude_x,dude_y




'If KeyHit( KEY_SPACE )

'PlaySound fire

'TBullet.CreateBullet dude_x,dude_y-16,bull

'EndIf

'Select







If 1

'If MouseDown(1)

color_rot:+1.5

color_rot:Mod 360

Local color:TRGBColor=HSVColor( color_rot,1,1 ).RGBColor()

Local rgb[]=[Int(color.Red()*255),Int(color.Green()*255),Int(color.Blue()*255)]



For Local k=1 To SPARKS_PER_FRAME

Local val1 : Int = (axis[0]+axis[3]+axis[6]+500)/10

Local val2 : Int = (axis[2]+axis[5]+axis[8]+500)/10



If val1<0

val1=val1*(-1)

EndIf

If val2<0

val2=val2*(-1)

EndIf



TSpark.CreateSpark val1,val2,rgb

'Print "axis[3]="+axis[3]+" axis[4]= "+axis[4]+" axis[5]= "+axis[5]

Print "X= "+val1

Print "Y= "+val2




  Next

EndIf




SetBlend MASKBLEND

UpdateEntities bullets

SetRotation 0




SetBlend LIGHTBLEND

UpdateEntities sparks

SetAlpha 1

SetRotation 0

SetColor 255,255,255



If KeyHit( Asc("D") ) show_debug=1-show_debug



If show_debug

  DrawText "MemAlloced="+GCMemAlloced(),0,0

EndIf




Flip



Wend

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''

 ' Until 0

  'EndIf

'  Until 1=1

  Else

  Print "Failed to create socket stream"

  EndIf




  Else

  Print "Failed to connect to server"

  EndIf




  CloseSocket client




  Else




  Print "Couldn't create TCP socket"




EndIf
