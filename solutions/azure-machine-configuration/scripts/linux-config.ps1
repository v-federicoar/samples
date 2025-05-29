configuration NginxInstall {

    Import-DscResource -ModuleName nx

    Node "localhost" {

        nxPackage nginx {
            Name = "nginx"
            Ensure = "Present"
        }
    }
}

NginxInstall
