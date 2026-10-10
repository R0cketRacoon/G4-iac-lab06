module "red" {
  source                 = "./modulos/red"
  nombreBase             = "lab06"
  cidrVpc                = "10.0.0.0/16"
  zonasDisponibilidad    = ["us-east-1a", "us-east-1b"]
  cidrsSubredesPublicas  = ["10.0.1.0/24", "10.0.2.0/24"]
  cidrsSubredesPrivadas  = ["10.0.10.0/24", "10.0.20.0/24"]
}

module "seguridad" {
  source      = "./modulos/seguridad"
  nombreBase  = "lab06"
  idVpc       = module.red.vpc_id
  regionAws   = "us-east-1"
}

module "endpoints" {
  source = "./modulos/endpoints"
}
