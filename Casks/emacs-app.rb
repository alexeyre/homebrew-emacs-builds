# frozen_string_literal: true

cask 'emacs-app' do
  name 'Emacs'
  desc 'GNU Emacs text editor'
  homepage 'https://github.com/jimeh/emacs-builds'

  version '30.2-1'

  on_arm do
    sha256 '8277021ed3eb716333120638ffc2565c1b893e9146e06738bb3521630f39eb19'
    url 'https://github.com/jimeh/emacs-builds/releases/download/Emacs-30.2-1/Emacs.2025-08-14.636f166.emacs-30-2-1.macOS-11.arm64.dmg'
    depends_on macos: '>= :big_sur'
  end
  on_intel do
    sha256 '9eade73998b1772fb8fba74cfa02ca25ab06285287a6b2bccafc14f609860f8c'
    url 'https://github.com/jimeh/emacs-builds/releases/download/Emacs-30.2-1/Emacs.2025-08-14.636f166.emacs-30-2-1.macOS-11.x86_64.dmg'
    depends_on macos: '>= :big_sur'
  end

  livecheck do
    url 'https://github.com/jimeh/emacs-builds.git'
    strategy :git do |tags|
      tags.map do |tag|
        m = /^Emacs-(\d+\.\d+[a-z]*(-\d+)?)$/.match(tag)
        next unless m

        m[1]
      end.compact
    end
  end

  conflicts_with(
    cask: %w[
      emacs-app-good
      emacs-app-monthly
      emacs-app-nightly
      emacs-app-nightly-28
      emacs-app-nightly-29
      emacs-app-pretest
      emacs
      emacs-nightly
      emacs-pretest
      emacs-mac
      emacs-mac-spacemacs-icon
    ]
  )

  app 'Emacs.app'
  binary "#{appdir}/Emacs.app/Contents/MacOS/bin/ebrowse"
  binary "#{appdir}/Emacs.app/Contents/MacOS/bin/emacs"
  binary "#{appdir}/Emacs.app/Contents/MacOS/bin/emacsclient"
  binary "#{appdir}/Emacs.app/Contents/MacOS/bin/etags"
  binary "#{appdir}/Emacs.app/Contents/Resources/include/emacs-module.h",
         target: "#{HOMEBREW_PREFIX}/include/emacs-module.h"
  binary "#{appdir}/Emacs.app/Contents/Resources/site-lisp/subdirs.el",
         target: "#{HOMEBREW_PREFIX}/share/emacs/site-lisp/subdirs.el"

  manpage "#{appdir}/Emacs.app/Contents/Resources/man/man1/ebrowse.1.gz"
  manpage "#{appdir}/Emacs.app/Contents/Resources/man/man1/emacs.1.gz"
  manpage "#{appdir}/Emacs.app/Contents/Resources/man/man1/emacsclient.1.gz"
  manpage "#{appdir}/Emacs.app/Contents/Resources/man/man1/etags.1.gz"

  zap trash: [
    '~/Library/Caches/org.gnu.Emacs',
    '~/Library/Preferences/org.gnu.Emacs.plist',
    '~/Library/Saved Application State/org.gnu.Emacs.savedState'
  ]

  postflight do
    # Clear quarantine before modifications
    system_command 'xattr', args: ['-cr', "#{appdir}/Emacs.app"], sudo: false
    
    # Download Assets.car from emacs-liquid-glass-icons repository
    assets_car_url = 'https://raw.githubusercontent.com/jimeh/emacs-liquid-glass-icons/main/Resources/Assets.car'
    assets_car_path = "#{appdir}/Emacs.app/Contents/Resources/Assets.car"
    
    system_command 'curl', args: ['-L', '-o', assets_car_path, assets_car_url]
    
    # Clear quarantine on downloaded file
    system_command 'xattr', args: ['-c', assets_car_path], sudo: false, must_succeed: false
    
    # Download Emacs.icns from emacs-liquid-glass-icons repository
    icns_url = 'https://github.com/jimeh/emacs-liquid-glass-icons/raw/refs/heads/main/Resources/EmacsLG1-Default.icns'
    icns_path = "#{appdir}/Emacs.app/Contents/Resources/Emacs.icns"
    
    system_command 'curl', args: ['-L', '-o', icns_path, icns_url]
    
    # Clear quarantine on downloaded file
    system_command 'xattr', args: ['-c', icns_path], sudo: false, must_succeed: false
    
    # Update Info.plist to set CFBundleIconName
    info_plist = "#{appdir}/Emacs.app/Contents/Info.plist"
    # Check if key exists, if not add it, otherwise set it
    result = system_command '/usr/libexec/PlistBuddy',
                            args: ['-c', 'Print :CFBundleIconName', info_plist],
                            sudo: false,
                            must_succeed: false
    if result.success?
      system_command '/usr/libexec/PlistBuddy',
                    args: ['-c', 'Set :CFBundleIconName EmacsLG1', info_plist],
                    sudo: false
    else
      system_command '/usr/libexec/PlistBuddy',
                    args: ['-c', 'Add :CFBundleIconName string EmacsLG1', info_plist],
                    sudo: false
    end
    
    # Re-sign with ad-hoc signature to allow modifications
    system_command 'codesign', args: ['--force', '--deep', '--sign', '-', "#{appdir}/Emacs.app"], sudo: false, must_succeed: false
    
    # Clear quarantine again after all modifications
    system_command 'xattr', args: ['-cr', "#{appdir}/Emacs.app"], sudo: false
  end
end
