FasdUAS 1.101.10   ��   ��    k             l     �� ��    O I Install in bundle/Contents/Scripts so it's visible from the Scripts menu       	  l     �� 
��   
 e _ This script was shipped with OmniWeb5.  Stefan K. from Omni said that we can treat this script    	     l     �� ��    9 3 as if it is covered under the Omni Source License.         l     ������  ��        j     �� �� 0 appname AppName  m         BibDesk         l     ������  ��        l    	    r     	    I    ��  
�� .earsffdralis        afdr  m        
 asup     �� ��
�� 
from  m    ��
�� fldmfldu��    o      ���� 0 
asupfolder 
asupFolder  B < "asup" = application support folder... buggy standard osax.        !   l  
  "�� " r   
  # $ # b   
  % & % n   
  ' ( ' 1    ��
�� 
psxp ( o   
 ���� 0 
asupfolder 
asupFolder & o    ���� 0 appname AppName $ o      ����  0 asupfolderpath asupFolderPath��   !  ) * ) l     ������  ��   *  + , + l   1 -�� - r    1 . / . b    / 0 1 0 b    - 2 3 2 b    ' 4 5 4 b    % 6 7 6 b     8 9 8 b     : ; : m     < < 0 *This menu contains AppleScripts to extend     ; o    ���� 0 appname AppName 9 m     = = � �'s functionality; to run a script, select it in the menu. To add scripts to the menu, save them in your Library/Application Support/    7 o    $���� 0 appname AppName 5 m   % & > >  /Scripts folder. See     3 o   ' ,���� 0 appname AppName 1 m   - . ? ?   Help for more info.    / o      ���� 0 
dialogtext 
dialogText��   ,  @ A @ l     ������  ��   A  B C B l  2 E D�� D I  2 E�� E F
�� .sysodlogaskr        TEXT E o   2 3���� 0 
dialogtext 
dialogText F �� G H
�� 
btns G J   4 9 I I  J K J m   4 5 L L  Show Sample Script    K  M N M m   5 6 O O  Open Scripts Folder    N  P�� P m   6 7 Q Q  OK   ��   H �� R��
�� 
dflt R m   < ? S S  OK   ��  ��   C  T U T l  F Q V�� V r   F Q W X W l  F M Y�� Y n   F M Z [ Z 1   I M��
�� 
bhit [ l  F I \�� \ 1   F I��
�� 
rslt��  ��   X o      ����  0 buttonreturned buttonReturned��   U  ] ^ ] l     ������  ��   ^  _ ` _ l  RL a�� a Z   RL b c d�� b =  R Y e f e o   R U����  0 buttonreturned buttonReturned f m   U X g g  Open Scripts Folder    c k   \ h h  i j i l  \ \������  ��   j  k l k l  \ \�� m��   m ? 9 find out if the folder exists or if we have to create it    l  n o n r   \ a p q p m   \ ]��
�� boovfals q o      ���� (0 shouldcreatefolder shouldCreateFolder o  r s r r   b k t u t b   b g v w v o   b c����  0 asupfolderpath asupFolderPath w m   c f x x  /Scripts    u o      ���� &0 scriptsfolderpath scriptsFolderPath s  y z y Q   l � { | } { n   o � ~  ~ 1   { ��
�� 
asdr  l  o { ��� � I  o {�� ���
�� .sysonfo4asfe       **** � 4   o w�� �
�� 
psxf � o   s v���� &0 scriptsfolderpath scriptsFolderPath��  ��   | R      ������
�� .ascrerr ****      � ****��  ��   } r   � � � � � m   � ���
�� boovtrue � o      ���� (0 shouldcreatefolder shouldCreateFolder z  � � � l  � �������  ��   �  � � � l  � ��� ���   � n h ask if we should create the folder, and create it via the shell for quick rescursive directory creation    �  � � � Z   � � � ����� � o   � ����� (0 shouldcreatefolder shouldCreateFolder � k   � � � �  � � � I  � ��� ���
�� .sysodlogaskr        TEXT � m   � � � � � |That Scripts folder doesn't exist yet. Would you like to create it now? (You may be prompted for an administrator password.)   ��   �  ��� � Q   � � � � � � k   � � � �  � � � I  � ��� ���
�� .sysoexecTEXT���     TEXT � b   � � � � � b   � � � � � m   � � � �  
mkdir -p '    � o   � ����� &0 scriptsfolderpath scriptsFolderPath � m   � � � �  '   ��   �  ��� � r   � � � � � m   � ���
�� boovfals � o      ���� (0 shouldcreatefolder shouldCreateFolder��   � R      ������
�� .ascrerr ****      � ****��  ��   � Q   � � � � � � k   � � � �  � � � I  � ��� � �
�� .sysoexecTEXT���     TEXT � b   � � � � � b   � � � � � m   � � � �  	mkdir -p     � o   � ����� &0 scriptsfolderpath scriptsFolderPath � m   � � � �  '    � �� ���
�� 
badm � m   � ���
�� boovtrue��   �  � � � r   � � � � � m   � ���
�� boovfals � o      ���� (0 shouldcreatefolder shouldCreateFolder �  ��� � l  � �������  ��  ��   � R      ������
�� .ascrerr ****      � ****��  ��   � I  � ��� � �
�� .sysodlogaskr        TEXT � m   � � � � F @You do not have sufficent user privileges to create this folder.    � �� � �
�� 
btns � m   � � � �  OK    � �� ���
�� 
dflt � m   � � � �  OK   ��  ��  ��  ��   �  � � � l  � �������  ��   �  � � � l  � ��� ���   � ] W open the folder for the user using the Finder (or user's preferred Finder replacement)    �  � � � Z  � � ����� � H   � � � � o   � ����� (0 shouldcreatefolder shouldCreateFolder � I �� ���
�� .sysoexecTEXT���     TEXT � b   � � � b   � � � m   � �  open '    � o  ���� &0 scriptsfolderpath scriptsFolderPath � m   � �  '   ��  ��  ��   �  ��� � l ������  ��  ��   d  � � � =   � � � o  ����  0 buttonreturned buttonReturned � m   � �  Show Sample Script    �  ��� � k  #H � �  � � � l ##������  ��   �  � � � r  #, � � � b  #( � � � o  #$����  0 asupfolderpath asupFolderPath � m  $' � �  /BD Test.scpt    � o      ����  0 testscriptpath testScriptPath �  � � � O  -F � � � I 3E�� ���
�� .aevtodocnull  �    alis � c  3A � � � l 3= ��� � n 3= � � � 4  6=�� �
�� 
psxf � o  9<����  0 testscriptpath testScriptPath � 1  36��
�� 
ascr��   � m  =@��
�� 
alis��   � m  -0 � ��null     ߀��  RjScript Editor.app�L��� 2���ڀ   Z �L   )       �(�K� ��ڠ �ToyS   alis    �  Macintosh HD               ��+GH+    RjScript Editor.app                                                Rk��H� v & � �����  	                AppleScript     ��'      ��,�      Rj  �  7Macintosh HD:Applications:AppleScript:Script Editor.app   $  S c r i p t   E d i t o r . a p p    M a c i n t o s h   H D  *Applications/AppleScript/Script Editor.app  / ��   �  ��� � l GG������  ��  ��  ��  ��  ��   `  ��� � l     ��~�  �~  ��       
�} �  � � � � � ��|�}   � �{�z�y�x�w�v�u�t�{ 0 appname AppName
�z .aevtoappnull  �   � ****�y 0 
asupfolder 
asupFolder�x  0 asupfolderpath asupFolderPath�w 0 
dialogtext 
dialogText�v  0 buttonreturned buttonReturned�u  0 testscriptpath testScriptPath�t   � �s ��r�q � ��p
�s .aevtoappnull  �   � **** � k    L � �   � �    � �  + � �  B � �  T � �  _�o�o  �r  �q   �   � 3 �n�m�l�k�j�i < = > ?�h�g L O Q�f S�e�d�c�b�a g�` x�_�^�]�\�[�Z � � ��Y � ��X � � � � � � ��W ��V�U�T
�n 
from
�m fldmfldu
�l .earsffdralis        afdr�k 0 
asupfolder 
asupFolder
�j 
psxp�i  0 asupfolderpath asupFolderPath�h 0 
dialogtext 
dialogText
�g 
btns
�f 
dflt�e 
�d .sysodlogaskr        TEXT
�c 
rslt
�b 
bhit�a  0 buttonreturned buttonReturned�` (0 shouldcreatefolder shouldCreateFolder�_ &0 scriptsfolderpath scriptsFolderPath
�^ 
psxf
�] .sysonfo4asfe       ****
�\ 
asdr�[  �Z  
�Y .sysoexecTEXT���     TEXT
�X 
badm�W  0 testscriptpath testScriptPath
�V 
ascr
�U 
alis
�T .aevtodocnull  �    alis�pM���l E�O��,b   %E�O�b   %�%b   %�%b   %�%E�O�����mva a a  O_ a ,E` O_ a   �fE` O�a %E` O *a _ /j a ,EW X  eE` O_  fa  j O a !_ %a "%j #OfE` W @X    a $_ %a %%a &el #OfE` OPW X  a '�a (a a )a  Y hO_  a *_ %a +%j #Y hOPY 5_ a ,  *�a -%E` .Oa / _ 0a _ ./a 1&j 2UOPY h ��alis    �  Macintosh HD               ��+GH+   X�Application Support                                             \;����        ����  	                Library     ��'      ����     X� X�  !�  ?Macintosh HD:Users:christiaanhofman:Library:Application Support   (  A p p l i c a t i o n   S u p p o r t    M a c i n t o s h   H D  2Users/christiaanhofman/Library/Application Support  /    ��   � �   v / U s e r s / c h r i s t i a a n h o f m a n / L i b r a r y / A p p l i c a t i o n   S u p p o r t / B i b D e s k � � �This menu contains AppleScripts to extend BibDesk's functionality; to run a script, select it in the menu. To add scripts to the menu, save them in your Library/Application Support/BibDesk/Scripts folder. See BibDesk Help for more info.    � � $ S h o w   S a m p l e   S c r i p t � � � / U s e r s / c h r i s t i a a n h o f m a n / L i b r a r y / A p p l i c a t i o n   S u p p o r t / B i b D e s k / B D   T e s t . s c p t�|  ascr  ��ޭ