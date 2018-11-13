# 1
Category.create!(
  name: 'Cameras',
  icon: '<i class="fas fa-camera fa-6x"></i>',
  has_peripheral: 1,
  is_peripheral: 0)

# 2
Category.create!(
  name: 'Cameras - Peripherals',
  icon: '<i class="fas fa-camera fa-6x"></i><i class="material-icons">P</i>',
  has_peripheral: 0,
  is_peripheral: 1)

# 3
Category.create!(
  name: 'Data Logger',
  icon: '<i class="material-icons">dock</i>',
  has_peripheral: 0,
  is_peripheral: 0)

# 4
Category.create!(
  name: 'Laptops',
  icon: '<i class="material-icons">computer</i>',
  has_peripheral: 1,
  is_peripheral: 0)

# 5
Category.create!(
  name: 'Laptops - Peripherals',
  icon: '<i class="material-icons">computerP</i>',
  has_peripheral: 0,
  is_peripheral: 1)

# 6
Category.create!(
  name: 'Tooling',
  icon: '<i class="fas fa-wrench fa-6x"></i>',
  has_peripheral: 0,
  is_peripheral: 0)

# 7
Category.create!(
  name: 'Accessories',
  icon: '<i class="fas fa-gem fa-6x"></i>',
  has_peripheral: 0,
  is_peripheral: 0)

# 8
Category.create!(
  name: 'Data Logger (Voltage) - Module',
  icon: '<i class="material-icons">offline_bolt</i>',
  has_peripheral: 1,
  is_peripheral: 0)

# 9
Category.create!(
  name: 'Data Logger (Voltage) - Module - Peripherals',
  icon: '<i class="material-icons">offline_boltP</i>',
  has_peripheral: 0,
  is_peripheral: 1)

# 10
Category.create!(
  name: 'Data Logger (Power)',
  icon: '<i class="fas fa-power-off fa-6x"></i>',
  has_peripheral: 0,
  is_peripheral: 0)

# 11
Category.create!(
  name: 'Data Logger (Temperature) - Module',
  icon: '<i class="fas fa-thermometer fa-6x"></i>',
  has_peripheral: 0,
  is_peripheral: 0)

# 12
Category.create!(
  name: 'Data Logger - Chassis',
  icon: '',
  has_peripheral: 0,
  is_peripheral: 0)

User.create!(email: 'wkkhaw1@sheffield.ac.uk', givenname: 'Wei Kin', sn: 'Khaw', permission_id: 3, username: 'aca16wkk')
User.create!(email: 'zjeng1@sheffield.ac.uk', givenname: 'Zer Jun', sn: 'Eng', permission_id: 3, username: 'acb16zje')
User.create!(email: 'atchapman1@sheffield.ac.uk', givenname: 'Alex', sn: 'Chapman', permission_id: 3, username: 'aca16atc')
User.create!(email: 'rchatterjee1@sheffield.ac.uk', givenname: 'Ritwesh', sn: 'Chatterjee', permission_id: 3, username: 'aca16rc')
User.create!(email: 'erica.smith@sheffield.ac.uk', givenname: 'Erica', sn: 'Smith', permission_id: 3, username: 'me1eds')

# 1
Item.create!(user_id: 1,
            category_id: 1,
            condition: 'Like New',
            name: 'GoPro Hero 5',
            location: 'Diamond',
            manufacturer: 'GoPro',
            model: 'Hero 5',
            serial: 'GPH5',
            acquisition_date: '2018-02-09',
            purchase_price: 100.1,
            image:  File.open(File.join(Rails.root, 'app/assets/images/assets/gopro.jpg')))

# 2
Item.create!(user_id: 1,
            category_id: 2,
            condition: 'Like New',
            name: 'MicroSD Card',
            location: 'Diamond',
            manufacturer: 'Kingston',
            model: 'Flash Card',
            serial: 'SD322',
            acquisition_date: '2018-03-09',
            purchase_price: 10.1,
            image:  File.open(File.join(Rails.root, 'app/assets/images/assets/microsd.jpg')))

# 3
Item.create!(user_id: 1,
            category_id: 2,
            condition: 'Like New',
            name: 'MicroSD Card',
            location: 'Diamond',
            manufacturer: 'Kingston',
            model: 'Flash Card',
            serial: 'SD644',
            acquisition_date: '2018-03-09',
            purchase_price: 10.1,
            image:  File.open(File.join(Rails.root, 'app/assets/images/assets/microsd.jpg')))

# 4
Item.create!(user_id: 1,
            category_id: 3,
            condition: 'Like New',
            name: 'Flir Thermal Camera',
            location: 'Diamond',
            manufacturer: 'Apple',
            model: 'FLIR ONE PRO',
            serial: 'FLR322',
            acquisition_date: '2018-03-22',
            purchase_price: 349.00,
            image:  File.open(File.join(Rails.root, 'app/assets/images/assets/flir.jpg')))

# 5
Item.create!(user_id: 2,
            category_id: 4,
            condition: 'Like New',
            name: 'MacBook Pro 15-inch',
            location: 'Diamond',
            manufacturer: 'Apple',
            model: 'MacBookPro14,3',
            serial: 'MPTR212/A',
            acquisition_date: '2018-03-22',
            purchase_price: 2349.00,
            image:  File.open(File.join(Rails.root, 'app/assets/images/assets/macbook.jpg')))

# 6
Item.create!(user_id: 2,
            category_id: 5,
            condition: 'Like New',
            name: 'Charging Cable',
            location: 'Diamond',
            manufacturer: 'Apple',
            model: 'Cable',
            serial: 'CC322',
            acquisition_date: '2018-03-22',
            purchase_price: 9.00,
            image:  File.open(File.join(Rails.root, 'app/assets/images/assets/charging_cable.jpg')))

ItemPeripheral.create!(parent_item_id: 1, peripheral_item_id: 2)
ItemPeripheral.create!(parent_item_id: 1, peripheral_item_id: 3)
ItemPeripheral.create!(parent_item_id: 5, peripheral_item_id: 6)