configuration NginxInstall {

    Import-DSCResource -Module nx

    Node "localhost" {

        nxPackage nginx {
            Name = "nginx"
            Ensure = "Present"
        }
    }
}

NginxInstall
