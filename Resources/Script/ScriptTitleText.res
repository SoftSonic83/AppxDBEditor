                  [30;47mThis Script modifies the Appx-Database of Windows 10 to change the Protection States[0m
                  [30;47mof preinstalled System-Apps so that they can be uninstalled.                        [0m
                  [30;47m                                                                                    [0m
                  [30;47mThe Appx-Database ("StateRepository-Machine.srd") of Windows 10 contains Information[0m
                  [30;47mabout installed Appx-Packages and controls their Distribution to the Users.  Some of[0m
                  [30;47mthe preinstalled System-Apps like "MicrosoftStore" or the "Content Delivery Manager"[0m
                  [30;47mbeing responsible for lot of Ads, Telemetry and self-installing Store-Apps cannot be[0m
                  [30;47muninstalled via Modern Settings Dialog or PowerShell. This is because these Packages[0m
                  [30;47mare protected from Uninstallation by a special Flag ("IsInbox") within the "Package"[0m
                  [30;47mTable of the Appx-Database. This Table lists all installed Appx-Packages. The Column[0m
                  [30;47mnamed "IsInbox" defines the Protection State for each Package by containing either a[0m
                  [30;47mValue of 1 which means the Package is a "Part Of The Box" and therefore it cannot be[0m
                  [30;47muninstalled or a Value of 0 meaning that the Appx-Package can be uninstalled for all[0m
                  [30;47mUsers.                                                                              [0m
                  [30;47m                                                                                    [0m
                  [30;47m[4mNOTICE:[24m                                                                             [0m
                  [30;47mBy Removing preinstalled and protected System-Apps you no longer get Feature-Updates[0m
                  [30;47mfor your Windows 10 Installation in the Future.                                     [0m
                  [30;47m                                                                                    [0m
                  [31;47m[4mDISCLAIMER & COPYRIGHT:[24m                                                             [0m
                  [31;47mTHIS SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,[0m
                  [31;47mINCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTI-[0m
                  [31;47mCULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR OR COPYRIGHT HOLDERS[0m
                  [31;47mBE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY WHETHER IN AN ACTION OF CONTRACT[0m
                  [31;47mTORT OR OTHERWISE, ARISING FROM OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE[0m
                  [31;47mOR OTHER DEALINGS IN THE SOFTWARE.                   COPYRIGHT © 2019 by SoftSonic83[0m